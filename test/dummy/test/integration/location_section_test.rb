# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class LocationSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @previous_geocoder = RecordingStudio::Location.geocoder
    RecordingStudio::Location.geocoder = RecordingStudioLocation::Geocoder::Fake.new
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
    RecordingStudio::Location.geocoder = @previous_geocoder
    Current.actor = @previous_actor
  end

  test "create section stores the heading and an empty location child" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
        @section = RecordingStudioPresskits.create_section!(
          press_kit_recording: kit,
          content_type: "RecordingStudio::Location::Location",
          actor: @user,
          title: "Project location",
          subtitle: "On site"
        )
      end
    end

    content = section_content(@section)
    assert_equal "Project location", @section.recordable.title
    assert_equal "On site", @section.recordable.subtitle
    assert_equal @section, content.parent_recording
    assert_kind_of RecordingStudio::Location::Location, content.recordable
    assert_nil content.recordable.name
    assert_equal [@section.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
  end

  test "one kit can hold many location sections" do
    kit = record_kit("Spring launch")
    first = add_location(kit, title: "Studio", name: "The Pavilion", locality: "Melbourne", country_code: "AU")
    second = add_location(kit, title: "Site", locality: "Fitzroy", country_code: "AU")
    third = add_location(kit, latitude: -37.81, longitude: 144.96)

    sections = RecordingStudioPresskits::KitQuery.sections_for(kit)
    assert_equal [first.id, second.id, third.id], sections.map(&:id)
    assert_equal ["The Pavilion", nil, nil], sections.map { |section| section_content(section).recordable.name }
    assert_equal ["Melbourne", "Fitzroy", nil], sections.map { |section| section_content(section).recordable.locality }
  end

  test "adding a location section from the editor opens the location fields" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudio::Location::Location" }
    end

    section = content_section(kit)
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_select "h1", text: "Location"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Location"
    assert_select "input[name='location[name]']"
    assert_select "input[name='location[address_line_1]']"
    assert_select "input[name='location[locality]']"
    assert_select "input[name='location[latitude]']"
    assert_select "input[name='location[longitude]']"
    refute_section_preview_card
  end

  test "saving a full address, a partial address, and coordinates only" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    full = add_location(kit, title: "Studio")
    city = add_location(kit, title: "City")
    pin = add_location(kit, title: "Pin")

    patch recording_studio_presskits.press_kit_section_path(kit, full), params: {
      location: {
        name: "The Pavilion",
        address_line_1: "12 Smith Street",
        address_line_2: "Level 2",
        locality: "Fitzroy",
        region: "Victoria",
        postal_code: "3065",
        country_code: "AU",
        latitude: "-37.798",
        longitude: "144.978"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, full)

    patch recording_studio_presskits.press_kit_section_path(kit, city), params: {
      location: { locality: "Melbourne", country_code: "AU" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, city)

    patch recording_studio_presskits.press_kit_section_path(kit, pin), params: {
      location: { latitude: "-37.81", longitude: "144.96" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, pin)

    assert_equal "The Pavilion", section_content(full).recordable.name
    assert_equal "12 Smith Street", section_content(full).recordable.address_line_1
    assert_equal "Fitzroy", section_content(full).recordable.locality
    assert_equal "AU", section_content(full).recordable.country_code
    assert_in_delta(-37.798, section_content(full).recordable.latitude)
    assert_equal "Melbourne", section_content(city).recordable.locality
    assert_nil section_content(city).recordable.name
    assert_nil section_content(pin).recordable.locality
    assert_in_delta(-37.81, section_content(pin).recordable.latitude)
    assert_in_delta(144.96, section_content(pin).recordable.longitude)
    refute_predicate RecordingStudio::Location.geocoder, :called? if RecordingStudio::Location.geocoder.respond_to?(:called?)
  end

  test "title and location save independently and invalid country keeps the typed values" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_location(kit, name: "The Pavilion", locality: "Melbourne", country_code: "AU")
    snapshot_id = section_content(section).recordable_id

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Project location", subtitle: "On site" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    section.reload
    assert_equal "Project location", section.recordable.title
    assert_equal "On site", section.recordable.subtitle
    assert_equal "The Pavilion", section_content(section).recordable.name

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      location: { name: "Kept", country_code: "AUS" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Could not save that section."
    assert_includes response.body, "must be a two-letter ISO country code"
    assert_select "input[name='location[name]'][value=?]", "Kept"
    assert_equal "The Pavilion", section_content(section.reload).recordable.name
    assert_equal snapshot_id, section_content(section).recordable_id

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      location: { name: "Southbank studio", locality: "Melbourne", country_code: "AU" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    content = section_content(section.reload)
    assert_equal "Southbank studio", content.recordable.name
    refute_equal snapshot_id, content.recordable_id
    assert_equal "Project location", section.recordable.title
  end

  test "an outsider cannot add or edit a location section" do
    kit = record_kit("Spring launch")
    section = add_location(kit, name: "The Pavilion")
    stranger = User.create!(
      email: "location-stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in stranger
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudio::Location::Location" }
    assert_response :forbidden

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      location: { name: "Nope" }
    }
    assert_response :forbidden
    assert_equal "The Pavilion", section_content(section.reload).recordable.name
  end

  test "editor preview owner preview and the public page share one location display" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_location(
      kit,
      title: "Project location",
      name: "The Pavilion",
      locality: "Melbourne",
      region: "Victoria",
      country_code: "AU",
      latitude: -37.81,
      longitude: 144.96
    )

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Project location"
    assert_select "#presskits-section-preview h3", text: "The Pavilion"
    assert_select "#presskits-section-preview h2", text: "The Pavilion", count: 0
    assert_select "#presskits-section-preview a[href*='openstreetmap.org'][target=_blank][rel='noopener noreferrer']",
                  text: "Open map"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select ".fp-section-title h2", text: "Project location"
    assert_includes response.body, "The Pavilion"

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "The Pavilion"
    assert_select "h2", text: "Project location"

    publish_kit!(kit, slug: "spring-launch-location")
    get kit.reload.publishable_public_path
    assert_response :success
    assert_blank_public_layout
    assert_includes response.body, "The Pavilion"
    assert_select "h2", text: "Project location"
  end

  test "a blank title falls back to Location without saving that word" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_location(kit, name: "The Pavilion", locality: "Melbourne")

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Location"
    assert_nil css_select("input[name='kit_section[title]']").first["value"]
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Location"
    assert_select "#presskits-section-preview h3", text: "The Pavilion"
    assert_nil section.reload.recordable.title
  end

  test "missing optional fields stay off the display and empty locations hide the preview card" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    empty = add_location(kit)
    named = add_location(kit, name: "Named place")

    get recording_studio_presskits.edit_press_kit_section_path(kit, empty)
    assert_response :success
    refute_section_preview_card

    get recording_studio_presskits.edit_press_kit_section_path(kit, named)
    assert_response :success
    assert_select "#presskits-section-preview h3", text: "Named place"
    refute_includes css_select("#presskits-section-preview").first.to_html, "openstreetmap.org/?mlat"
  end

  test "reordering duplicating trashing and restoring keep location data" do
    kit = record_kit("Spring launch")
    notes = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    section = add_location(kit, title: "Studio", name: "The Pavilion", locality: "Melbourne", country_code: "AU")
    content = section_content(section)

    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [section.id, notes.id],
      actor: @user
    )
    assert_equal [section.id, notes.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)

    duplicate = kit.duplicate_in_place!(actor: @user)
    copied = RecordingStudioPresskits::KitQuery.sections_for(duplicate).find do |child|
      RecordingStudioPresskits::LocationContent.type?(RecordingStudioPresskits::KitQuery.section_content(child))
    end
    copied_content = section_content(copied)
    assert_equal "Studio (Copy)", copied.recordable.title
    assert_equal "The Pavilion", copied_content.recordable.name
    refute_equal section.id, copied.id
    refute_equal content.id, copied_content.id

    sign_in @user
    switch_to_root(@root)
    delete recording_studio_presskits.press_kit_section_path(kit, section)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert content.reload.trashed_at.present?
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), section.id

    section.recording_studio_trashable_restore!(actor: @user)
    assert_nil section.reload.trashed_at
    assert_nil content.reload.trashed_at
    assert_equal "The Pavilion", section_content(section).recordable.name
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit.reload).map(&:id), section.id
  end

  test "unpublished location edits stay off the published page" do
    kit = record_kit("Spring launch")
    section = add_location(kit, title: "Studio", name: "The Pavilion", locality: "Melbourne")
    publish_kit!(kit, slug: "location-snapshot")
    original_id = section_content(section).recordable_id

    @root.revise(section_content(section), actor: @user) do |location|
      location.name = "Secret annex"
      location.locality = "Sydney"
    end

    get kit.reload.publishable_public_path
    assert_response :success
    public_name = published_location_name(kit, original_id)
    assert_equal "The Pavilion", public_name if public_name
    refute_includes response.body, "Secret annex" if public_snapshot?(kit)

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "Secret annex"
  end

  test "complete kit section payloads keep location order" do
    kit = record_kit("Spring launch")
    notes = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    first = add_location(kit, title: "Studio", name: "The Pavilion", locality: "Melbourne")
    second = add_location(kit, title: "Site", locality: "Fitzroy", country_code: "AU")
    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, notes.id, first.id],
      actor: @user
    )

    payloads = RecordingStudioPresskits::KitQuery.sections_for(kit.reload).map do |section|
      RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    end

    assert_equal ["Site", "Notes", "Studio"], payloads.map { |payload| payload[:title] }
    assert_equal "Fitzroy", payloads.first.dig(:location, :locality)
    refute payloads[1].key?(:location)
    assert_equal "The Pavilion", payloads.last.dig(:location, :name)
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_location(kit, title: nil, **attributes)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudio::Location::Location",
      actor: @user,
      title: title
    )
    return section if attributes.empty?

    content = section_content(section)
    @root.revise(content, actor: @user) do |location|
      attributes.each { |name, value| location.public_send(:"#{name}=", value) }
    end
    section
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def content_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      RecordingStudioPresskits::LocationContent.type?(section_content(section))
    end
  end

  def publish_kit!(kit, slug:)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: {
        slug: slug,
        status: "published",
        meta_robots: "index,follow"
      }
    )
    raise result.error if result.failure?

    result.value
  end

  def public_snapshot?(kit)
    kit.respond_to?(:currently_published_recording) && kit.currently_published_recording.present? &&
      kit.currently_published_recording != kit
  end

  def published_location_name(kit, original_id)
    return RecordingStudio::Location::Location.find(original_id).name if RecordingStudio::Location::Location.exists?(original_id)

    nil
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

  def refute_section_preview_card
    assert_select "#presskits-section-preview .fp-card", count: 0
  end
end
