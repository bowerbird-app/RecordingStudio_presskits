# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class LocationSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "location-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Location Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "create section stores the heading and no location row" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::LocationSection.count }, 1 do
        assert_no_difference -> { RecordingStudio::Location::Location.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::LocationSection",
            actor: @user,
            title: "Where to find us",
            subtitle: "Two rooms"
          )
        end
      end
    end

    content = RecordingStudioPresskits::KitQuery.section_content(@section)
    assert_equal "Where to find us", @section.recordable.title
    assert_equal "Two rooms", @section.recordable.subtitle
    assert_equal @section, content.parent_recording
    assert_kind_of RecordingStudioPresskits::LocationSection, content.recordable
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "Where to find us",
        subtitle: "Two rooms",
        content_type: "RecordingStudioPresskits::LocationSection",
        content_id: content.id,
        locations: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "places hang off the location section and stay off the kit header" do
    kit = record_kit("Spring launch")
    kit.record(RecordingStudio::Location::Location, actor: @user, parent_recording: kit) do |location|
      location.title = "Harbour Gallery"
      location.location_type = "venue"
      location.locality = "Sydney"
      location.country_code = "AU"
    end
    section = add_location_section(kit)
    content = section_content(section)
    first = record_location(content, title: "The Pavilion", locality: "Melbourne")
    second = record_location(content, title: "Harbour Hall", locality: "Sydney")
    snapshot_id = first.recordable_id

    assert_equal content, RecordingStudioPresskits::KitQuery.section_content(section)
    assert_equal [first.id, second.id], RecordingStudioPresskits::LocationSection.active_locations(content).map(&:id)
    assert_empty section.child_recordings.select { |child| child.recordable.is_a?(RecordingStudio::Location::Location) }
    assert_equal "Harbour Gallery", RecordingStudioPresskits::KitLocation.recordable_for(kit).title
    refute_equal first.id, RecordingStudioPresskits::KitLocation.recording_for(kit).id

    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      @root.revise(first, actor: @user) do |location|
        location.title = "The Pavilion, Southbank"
      end
    end

    assert_equal "The Pavilion", RecordingStudio::Location::Location.find(snapshot_id).title
    assert_equal "The Pavilion, Southbank", first.reload.recordable.title
    refute_equal snapshot_id, first.recordable_id
    assert_equal "Harbour Gallery", RecordingStudioPresskits::KitLocation.recordable_for(kit).title
  end

  test "an invalid country stays on the form" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_location_section(kit)

    assert_no_difference -> { RecordingStudio::Location::Location.count } do
      post recording_studio_presskits.press_kit_section_locations_path(kit, section), params: {
        location: { title: "Nope", country_code: "Australia" }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "must be a two-letter ISO country code"
    assert_includes response.body, "Nope"
  end

  test "kit section order leaves places in place and locations are not orderable" do
    kit = record_kit("Spring launch")
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    places = add_location_section(kit, title: "Where to find us")
    content = section_content(places)
    child = record_location(content, title: "The Pavilion", locality: "Melbourne")

    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [places.id, text.id],
      actor: @user
    )

    assert_equal [places.id, text.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), child.id
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::LocationSection")

    names = RecordingStudioPresskits::Engine.routes.named_routes.names.map(&:to_s)
    refute names.any? { |name| name.include?("location_order") }
    assert_includes names, "press_kit_section_locations"
  end

  test "deleting one place trashes that recording only" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_location_section(kit)
    content = section_content(section)
    first = record_location(content, title: "The Pavilion", locality: "Melbourne")
    second = record_location(content, title: "Harbour Hall", locality: "Sydney")
    location_count = RecordingStudio::Location::Location.count

    delete recording_studio_presskits.press_kit_section_location_path(kit, section, first)

    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert first.reload.trashed_at.present?
    assert_nil second.reload.trashed_at
    assert_nil content.reload.trashed_at
    assert_nil section.reload.trashed_at
    assert_equal location_count, RecordingStudio::Location::Location.count
    assert_equal [second.id], RecordingStudioPresskits::LocationSection.active_locations(content).map(&:id)
  end

  test "deleting the section trashes that subtree and leaves the kit location" do
    kit = record_kit("Spring launch")
    other = record_kit("Autumn recap")
    sign_in @user
    switch_to_root(@root)
    kit.record(RecordingStudio::Location::Location, actor: @user, parent_recording: kit) do |location|
      location.title = "Harbour Gallery"
      location.location_type = "venue"
      location.locality = "Sydney"
      location.country_code = "AU"
    end
    section = add_location_section(kit, title: "Where to find us")
    content = section_content(section)
    first = record_location(content, title: "The Pavilion", locality: "Melbourne")
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    sibling = add_location_section(kit, title: "Extra")
    sibling_place = record_location(section_content(sibling), title: "Kept", locality: "Brisbane")
    outsider = add_location_section(other, title: "Elsewhere")
    outside_place = record_location(section_content(outsider), title: "Other kit", locality: "Perth")
    kit_location = RecordingStudioPresskits::KitLocation.recording_for(kit)
    recording_count = RecordingStudio::Recording.count
    location_count = RecordingStudio::Location::Location.count

    delete recording_studio_presskits.press_kit_section_path(kit, section)

    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert_equal true, section.trash_root
    assert content.reload.trashed_at.present?
    assert first.reload.trashed_at.present?
    assert_nil kit.reload.trashed_at
    assert_nil kit_location.reload.trashed_at
    assert_equal "Harbour Gallery", kit_location.recordable.title
    assert_nil text.reload.trashed_at
    assert_nil sibling.reload.trashed_at
    assert_nil sibling_place.reload.trashed_at
    assert_nil outside_place.reload.trashed_at
    assert_equal recording_count, RecordingStudio::Recording.count
    assert_equal location_count, RecordingStudio::Location::Location.count
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), section.id
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), text.id
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), sibling.id
  end

  test "the editor creates a location section and edits places through search fields" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::LocationSection.count }, 1 do
      assert_no_difference -> { RecordingStudio::Location::Location.count } do
        post recording_studio_presskits.press_kit_sections_path(kit),
             params: { type: "RecordingStudioPresskits::LocationSection" }
      end
    end
    follow_redirect!
    assert_response :success
    section = location_section(kit)
    new_location = recording_studio_presskits.new_press_kit_section_location_path(kit, section)
    assert_equal "Location", section.recordable.title
    assert_select ".fp-section-title h2", text: "Location"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]']"
    assert_select "input[name='kit_section[subtitle]']"
    assert_select "#presskits-section-update button[type=submit]", text: "Update"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "h1", text: "Location"
    refute_select "input[name='kit_section[title]']"
    assert_select "#presskits-section-content-form", count: 0
    assert_includes css_select("#presskits-section-fields").first.to_html, new_location
    assert_select "#presskits-section-actions a[href='#{new_location}']" do
      assert_select "span", text: "Location"
      assert_select "[data-flat-pack--icon-name-value='plus']", count: 1
    end

    get new_location
    assert_response :success
    assert_select "input[name='location[title]']"
    assert_includes response.body, "recording-studio-location--place-search"

    post recording_studio_presskits.press_kit_section_locations_path(kit, section), params: {
      location: {
        title: "The Pavilion",
        location_type: "venue",
        name: "The Pavilion",
        locality: "Melbourne",
        region: "Victoria",
        country_code: "AU"
      }
    }
    place = RecordingStudioPresskits::LocationSection.active_locations(section_content(section)).first
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_location_path(kit, section, place)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Location added."
    assert_select "input[name='location[title]'][value='The Pavilion']"
    assert_includes response.body, "recording-studio-location--place-search"

    post recording_studio_presskits.press_kit_section_locations_path(kit, section), params: {
      location: {
        title: "Harbour Hall",
        location_type: "venue",
        locality: "Sydney",
        country_code: "AU"
      }
    }
    follow_redirect!
    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Where to find us", subtitle: "Two rooms" }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_path(kit)
    preview = css_select("#presskits-editor-preview").first.to_html
    assert_includes preview, "Where to find us"
    assert_includes preview, "Two rooms"
    assert_includes preview, "The Pavilion"
    assert_includes preview, "Harbour Hall"

    publish_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-places"
    assert_response :success
    assert_includes response.body, "Where to find us"
    assert_includes response.body, "The Pavilion"
    assert_includes response.body, "Harbour Hall"
    assert_select "[data-cover-location]", count: 0
  end

  test "a text section has no location button" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    text = content_section(kit, RecordingStudioPresskits::Text)
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_section_path(kit, text)
    assert_response :success
    assert_select "#presskits-section-actions", count: 0
    refute_includes response.body, recording_studio_presskits.new_press_kit_section_location_path(kit, text)
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_location_section(kit, title: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::LocationSection",
      actor: @user,
      title: title
    )
  end

  def location_section(kit)
    content_section(kit, RecordingStudioPresskits::LocationSection)
  end

  def content_section(kit, type)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      RecordingStudioPresskits::KitQuery.section_content(section)&.recordable.is_a?(type)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def record_location(content, title:, locality:)
    content.record(RecordingStudio::Location::Location, parent_recording: content, actor: @user) do |location|
      location.title = title
      location.location_type = "venue"
      location.locality = locality
      location.country_code = "AU"
    end
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-places", status: "published" }
    )
    raise result.error if result.failure?
  end

  def switch_to_root(root)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root.id,
        return_to: "/recording_studio_presskits"
      }
    }
    follow_redirect! if response.redirect?
  end
end
