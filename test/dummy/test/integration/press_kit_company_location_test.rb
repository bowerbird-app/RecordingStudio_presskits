# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitCompanyLocationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "company-location-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Company Location Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "hero hides company and location when neither exists" do
    kit = record_kit("Spring launch")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-company]", count: 0
    assert_select "#presskits-kit-cover [data-cover-location]", count: 0
    refute_includes css_select("#presskits-kit-cover").text, "Harbour Studio"
    refute_includes css_select("#presskits-kit-cover").text, "Harbour Gallery"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-header [data-cover-company]", count: 0
    assert_select "#presskits-kit-header [data-cover-location]", count: 0
  end

  test "hero shows the root company and kit location on the public kit and editor" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    create_company!("Harbour Studio")
    create_location!(kit, title: "Harbour Gallery", locality: "Sydney")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-company]", text: /Harbour Studio/
    assert_select "#presskits-kit-cover [data-cover-location]", text: /Harbour Gallery/
    hero = css_select("#presskits-kit-cover").first.to_html
    assert_operator hero.index("Harbour Studio"), :<, hero.index("Harbour Gallery")
    assert_operator hero.index("data-cover-description"), :<, hero.index("data-cover-location")
    assert_operator hero.index("data-cover-title"), :<, hero.index("data-cover-location")

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-header [data-cover-company]", text: /Harbour Studio/
    assert_select "#presskits-kit-header [data-cover-location]", text: /Harbour Gallery/
    header = css_select("#presskits-kit-header").first.to_html
    assert_operator header.index("data-cover-description"), :<, header.index("data-cover-location")
    assert_operator header.index("data-cover-title"), :<, header.index("data-cover-location")
  end

  test "header editor shows location search fields and can create revise and clear a place" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "input[name='location[title]']"
    assert_select "input[name='location[location_type]'][value='venue']"
    assert_includes response.body, "recording-studio-location--place-search"
    refute_select "#presskits-header-edit-preview"

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch" },
      location: { title: "Harbour Gallery", location_type: "venue", locality: "Sydney", country_code: "AU" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    location = kit_location(kit)
    assert_equal "Harbour Gallery", location.recordable.title
    assert_equal "venue", location.recordable.location_type
    assert_equal "Sydney", location.recordable.locality
    assert_equal "AU", location.recordable.country_code

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "input[name='location[title]'][value='Harbour Gallery']"

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch" },
      location: { title: "Harbour Gallery, Sydney", location_type: "venue", locality: "Sydney", country_code: "AU" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_equal location.id, kit_location(kit).id
    assert_equal "Harbour Gallery, Sydney", kit_location(kit).recordable.title

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch" },
      location: { title: "", location_type: "", locality: "", country_code: "" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_nil kit_location(kit)
    assert location.reload.trashed_at
  end

  test "saving the header without location params leaves an existing place" do
    kit = record_kit("Spring launch")
    create_location!(kit, title: "Harbour Gallery", locality: "Sydney")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch, take two" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_equal "Harbour Gallery", kit_location(kit).recordable.title
    assert_equal "Spring launch, take two", kit.reload.recordable.title
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def create_company!(name)
    RecordingStudioCompany.create(@root, actor: @user, name: name)
  end

  def create_location!(kit, title:, locality:)
    kit.record(RecordingStudio::Location::Location, actor: @user, parent_recording: kit) do |location|
      location.title = title
      location.location_type = "venue"
      location.locality = locality
      location.country_code = "AU"
    end
  end

  def kit_location(kit)
    RecordingStudioPresskits::KitLocation.recording_for(kit)
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-company-#{SecureRandom.hex(4)}", status: "published" }
    )
    raise result.error if result.failure?

    kit.reload
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
