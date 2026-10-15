# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitEmbargoTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "embargo-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Embargo Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "a published kit with no embargo stays fully public" do
    kit = publish_story("spring-embargo-open")

    assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    assert_includes RecordingStudioPresskits::KitQuery.discoverable_for(actor: nil).map(&:id), kit.id

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Secret notes"
    refute_select "#presskits-preview-embargo"
    refute_select "#presskits-kit-embargo"
    refute_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "an unpublished kit stays unavailable even when an embargo is stored" do
    kit = record_kit("Spring launch")
    record_block(kit, "Secret notes")
    hold_kit!(kit)

    assert_equal :unavailable, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    refute_includes RecordingStudioPresskits::KitQuery.discoverable_for(actor: nil).map(&:id), kit.id
  end

  test "anonymous visitors get an embargoed preview and no protected content" do
    kit = publish_story("spring-embargo-preview")
    hold_kit!(kit)
    Current.actor = nil

    assert_equal :preview, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    assert_equal :embargoed, RecordingStudioPresskits::Visibility.preview_reason_for(kit, actor: nil)
    assert_includes RecordingStudioPresskits::KitQuery.discoverable_for(actor: nil).map(&:id), kit.id

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='preview']"
    assert_select "#presskits-kit-cover #presskits-preview-embargo p", text: /Embargoed until/
    assert_select "#presskits-preview-embargo p", text: "Not for publication until embargo lifts."
    refute_select "#presskits-preview-embargo p.text-xs"
    assert_notice_under_location("#presskits-kit-cover", "presskits-preview-embargo")
    refute_select "#presskits-embargo-marker"
    assert_includes response.body, "Spring launch"
    refute_includes response.body, "Secret notes"
    refute_includes response.body, "Doors at noon."
    refute_select "#presskits-public-sections"
    refute_select "[data-cover-download]"
    refute_select "#presskits-cover-image"
    assert_select "meta[name='robots'][content='noindex, nofollow']"
    refute_select "meta[name='description']"
    refute_includes response.body, "og:description"
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "a hidden visibility fallback 404s without the kit while the embargo denies" do
    kit = publish_story("spring-embargo-hidden")
    hold_kit!(kit, fallback: :hidden)
    Current.actor = nil

    assert_equal :hidden, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    refute_includes RecordingStudioPresskits::KitQuery.discoverable_for(actor: nil).map(&:id), kit.id

    get kit.publishable_public_path
    assert_response :not_found
    refute_includes response.body, "Spring launch"
    refute_includes response.body, "Secret notes"
    refute_select "#presskits-preview-embargo"
    refute_select "#presskits-kit-embargo"
  end

  test "someone with early access sees the full kit and can download" do
    kit = publish_story("spring-embargo-early", build: true)
    hold_kit!(kit)
    sign_in @user
    Current.actor = @user

    assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: @user, kit: kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Secret notes"
    assert_select "#presskits-kit-cover #presskits-kit-embargo p", text: /Embargoed until/
    assert_select "#presskits-kit-embargo p", text: "Not for publication until embargo lifts."
    assert_notice_under_location("#presskits-kit-cover", "presskits-kit-embargo")
    assert_select "[data-cover-download]", count: 1
    assert_equal "private, no-store", response.headers["Cache-Control"]

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :redirect

    get recording_studio_downloadable.recording_package_status_path(kit)
    assert_response :success
  end

  test "view access does not grant the download" do
    kit = publish_story("spring-embargo-view-only", build: true)
    hold_kit!(kit)
    stranger = User.create!(
      email: "desk-#{SecureRandom.hex(4)}@presskits.test",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    result = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: stranger,
      role: :view,
      manager_actor: @user
    )
    raise result.error if result.failure?
    sign_in stranger
    Current.actor = stranger

    assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: stranger, kit: kit)
    refute kit.recordable.downloadable_available_for?(actor: stranger, action: :"presskits.kit_download")

    get kit.publishable_public_path
    assert_response :success
    assert_includes response.body, "Secret notes"
    assert_select "[data-cover-download]", count: 0

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden

    get recording_studio_downloadable.recording_package_status_path(kit)
    assert_response :forbidden

    post recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden
  end

  test "an existing zip stays closed until the embargo lifts" do
    kit = publish_story("spring-embargo-zip", build: true)
    assert kit.downloadable_package.present?
    hold_kit!(kit)
    Current.actor = nil

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden

    get recording_studio_downloadable.recording_package_status_path(kit)
    assert_response :forbidden

    travel_to 2.days.from_now do
      assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
      assert kit.recordable.downloadable_available_for?(actor: nil, action: :"presskits.kit_download")

      get kit.publishable_public_path
      assert_response :success
      assert_select "[data-presskits-presentation='full']"
      refute_select "#presskits-kit-embargo"
      refute_select "#presskits-preview-embargo"

      get recording_studio_downloadable.recording_package_path(kit)
      assert_response :redirect
    end
  end

  test "the embargo gem editor saves a hold and rejects a past release" do
    kit = publish_story("spring-embargo-editor")
    sign_in @user
    switch_to_root(@root)
    edit_path = recording_studio_embargo.edit_recording_embargo_path(kit)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#embargo-editor-modal"
    assert_select "turbo-frame#embargo_editor"
    assert_select "[data-modal-id='embargo-editor-modal'] #embargo_button_#{kit.id} a[href='#{edit_path}'][data-turbo-frame='embargo_editor']",
                  text: "+ Embargo"
    refute_select "#presskits-header-embargo"

    get edit_path
    assert_response :success
    assert_select "h1", text: "Embargo"
    assert_select "#embargo-form"
    assert_includes response.body, "Display your press kit as a preview marked for embargo"
    assert_includes response.body, "Embargo enabled"
    assert_includes response.body, "Early access"

    patch recording_studio_embargo.recording_embargo_path(kit), params: {
      embargo: {
        enabled: "1",
        lifts_at: "#{Date.yesterday}T09:00",
        time_zone: "UTC",
        early_access: "1"
      }
    }
    assert_response :unprocessable_entity
    refute kit.reload.embargo_active?

    patch recording_studio_embargo.recording_embargo_path(kit), params: {
      embargo: {
        enabled: "1",
        lifts_at: "#{Date.tomorrow}T15:30",
        time_zone: "UTC",
        early_access: "1"
      }
    }
    assert_redirected_to edit_path
    assert kit.reload.embargo_active?
    assert_kind_of RecordingStudioEmbargo::Embargo, kit.current_embargo
    assert_equal :preview, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: @user, kit: kit)
  end

  test "a turbo frame loads the editor without layout and a save stays in the frame" do
    kit = publish_story("spring-embargo-frame")
    sign_in @user
    switch_to_root(@root)
    edit_path = recording_studio_embargo.edit_recording_embargo_path(kit)
    headers = { "Turbo-Frame" => "embargo_editor" }

    get edit_path, headers: headers
    assert_response :success
    assert_select "turbo-frame#embargo_editor #embargo-form"
    refute_match(/<html/i, response.body)

    patch recording_studio_embargo.recording_embargo_path(kit),
          params: {
            embargo: {
              enabled: "1",
              lifts_at: "#{Date.yesterday}T09:00",
              time_zone: "UTC",
              early_access: "1"
            }
          },
          headers: headers
    assert_response :unprocessable_entity
    assert_select "turbo-frame#embargo_editor"
    refute kit.reload.embargo_active?

    patch recording_studio_embargo.recording_embargo_path(kit),
          params: {
            embargo: {
              enabled: "1",
              lifts_at: "#{Date.tomorrow}T15:30",
              time_zone: "UTC",
              early_access: "1"
            }
          },
          headers: headers.merge("Accept" => "text/vnd.turbo-stream.html")
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "Embargo saved"
    assert_includes response.body, %(target="embargo_editor")
    assert_includes response.body, %(id="embargo_button_#{kit.id}")
    assert_includes response.body, "Embargoed"
    assert kit.reload.embargo_active?
  end

  test "an active embargo shows the notice on the preview and the header" do
    kit = publish_story("spring-embargo-notice")
    hold_kit!(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-cover #presskits-kit-embargo p", text: /Embargoed until/
    assert_select "#presskits-kit-embargo p", text: "Not for publication until embargo lifts."
    refute_select "#presskits-kit-embargo p.text-xs"
    assert_notice_under_location("#presskits-kit-cover", "presskits-kit-embargo")
    assert_includes response.body, "Secret notes"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-header #presskits-kit-cover #presskits-header-embargo", text: /Embargoed until/
    assert_select "#presskits-header-embargo p.text-xs", text: "Not for publication until embargo lifts."
    assert_notice_under_location("#presskits-kit-header", "presskits-header-embargo")
    assert_select "#presskits-kit-header [data-cover-title]", text: "Spring launch"
  end

  test "duplicating a kit clears the embargo window" do
    kit = publish_story("spring-embargo-copy")
    hold_kit!(kit)

    duplicate = kit.duplicate_in_place!(actor: @user)

    assert kit.reload.embargo_active?
    refute duplicate.embargo_active?
    refute duplicate.current_embargo&.enabled?
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = title
      press_kit.description = "Doors at noon."
    end
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      title: title,
      actor: @user
    )
  end

  def publish_kit!(kit, slug:)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: slug, status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    kit.reload
  end

  def publish_story(slug, build: false)
    kit = record_kit("Spring launch")
    record_block(kit, "Secret notes")
    if build
      perform_enqueued_jobs { publish_kit!(kit, slug: slug) }
    else
      publish_kit!(kit, slug: slug)
    end
    kit.reload
  end

  def hold_kit!(kit, fallback: :preview, early_access: true)
    RecordingStudioPresskits::KitSettings.save_fallback!(
      recording: kit,
      fallback: fallback,
      actor: @user
    )
    kit.embargo_set!(
      {
        enabled: true,
        lifts_at: 1.day.from_now.change(sec: 0),
        time_zone: "UTC",
        early_access: early_access
      },
      actor: @user
    )
    kit.reload
  end

  def assert_notice_under_location(scope, notice_id)
    cover = css_select(scope).first.to_html
    assert_includes cover, %(id="#{notice_id}")
    assert_operator cover.index("data-cover-title"), :<, cover.index(notice_id)
    if cover.include?("data-cover-location")
      assert_operator cover.index("data-cover-location"), :<, cover.index(notice_id)
    end
    if cover.include?("data-cover-wide-location")
      assert_operator cover.index("data-cover-wide-location"), :<, cover.index(notice_id)
    end
    return unless cover.include?("data-cover-actions")

    assert_operator cover.index(notice_id), :<, cover.index("data-cover-actions")
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
