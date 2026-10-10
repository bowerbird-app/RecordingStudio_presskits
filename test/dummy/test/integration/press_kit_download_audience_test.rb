# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "uri"

class PressKitDownloadAudienceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @previous_actor = Current.actor
    @user = create_user("kit-audience")
    @stranger = create_user("kit-stranger")
    @workspace = Workspace.create!(name: "Audience Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "Anyone saved through Downloads lets an anonymous visitor download" do
    kit = publish_downloadable_kit!("audience-anyone")
    save_download_audience!(kit, :public)
    visit_as(nil)

    assert_download_allowed(kit)
  end

  test "Signed in saved through Downloads blocks anonymous visitors and lets a signed-in user with no grant download" do
    kit = publish_downloadable_kit!("audience-signed-in")
    save_download_audience!(kit, :signed_in)

    visit_as(nil)
    assert_download_refused(kit)

    visit_as(@stranger)
    assert_download_allowed(kit)
  end

  test "People with access saved through Downloads refuses anonymous and signed-in visitors with no grant" do
    kit = publish_downloadable_kit!("audience-granted-refuse")
    save_download_audience!(kit, :granted)

    visit_as(nil)
    assert_download_refused(kit)

    visit_as(@stranger)
    assert_download_refused(kit)
  end

  test "People with access lets download, edit, and admin grants download and refuses view-only" do
    kit = publish_downloadable_kit!("audience-granted-allow")
    save_download_audience!(kit, :granted)
    viewer = grant_role!(:view)
    editor = grant_role!(:edit)

    visit_as(viewer)
    assert_download_refused(kit)

    visit_as(editor)
    assert_download_allowed(kit)

    visit_as(@user)
    assert_download_allowed(kit)

    with_download_role do
      downloader = grant_role!(:download)
      visit_as(downloader)
      assert_download_allowed(kit)
    end
  end

  test "public kit uses the signed-in visitor even if Current.actor still holds an editor" do
    kit = publish_downloadable_kit!("audience-leftover-actor")
    save_download_audience!(kit, :granted)
    sign_in @stranger
    Current.actor = @user

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
    refute_includes response.body, "Download kit"

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_includes [401, 403], response.status
  end

  test "switching from Anyone to Signed in immediately blocks an anonymous request to a built package path" do
    kit = publish_downloadable_kit!("audience-switch-signed-in")
    save_download_audience!(kit, :public)
    visit_as(nil)

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :redirect
    signed_url = response.redirect_url
    assert_predicate signed_url, :present?
    refute_package_path(signed_url)

    save_download_audience!(kit, :signed_in)
    visit_as(nil)

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_response :forbidden
    assert_nil response.redirect_url

    get signed_blob_request_path(signed_url)
    assert_response :success
    assert_equal 5.minutes, RecordingStudioDownloadable::SIGNED_URL_EXPIRES_IN
  end

  private

  def create_user(prefix)
    User.create!(
      email: "#{prefix}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def publish_downloadable_kit!(slug)
    kit = @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    library = @root.image_library(actor: @user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")),
      filename: "harbour-gallery.jpg",
      content_type: "image/jpeg"
    )
    photo = library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
    kit.place_library_image(attachment_recording: photo, actor: @user)
    perform_enqueued_jobs do
      result = RecordingStudioPublishable::Services::Publishables::Update.call(
        parent_recording: kit,
        actor: @user,
        attributes: { slug: slug, status: "published", meta_robots: "index,follow" }
      )
      raise result.error if result.failure?
    end
    kit.reload
    assert kit.downloadable_ready?
    kit
  end

  def save_download_audience!(kit, audience)
    sign_in @user
    Current.actor = @user
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @root.id,
        return_to: "/recording_studio_presskits"
      }
    }
    follow_redirect! if response.redirect?

    patch recording_studio_presskits.press_kit_downloads_path(kit), params: {
      downloads: { audience: audience.to_s }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_equal audience.to_sym, RecordingStudioPresskits::KitDownload.effective_audience(kit.reload)
    reset_visitor!
    kit.reload
  end

  def grant_role!(role)
    user = create_user("kit-#{role}")
    result = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: user,
      role: role,
      manager_actor: @user
    )
    raise result.error if result.failure?

    user
  end

  def with_download_role
    Workspace.accessible_roles :view, :download, :edit, :admin
    yield
  ensure
    Workspace.remove_instance_variable(:@accessible_role_set) if Workspace.instance_variable_defined?(:@accessible_role_set)
  end

  def visit_as(user)
    reset_visitor!
    return if user.blank?

    sign_in user
    Current.actor = user
  end

  def reset_visitor!
    sign_out :user
    Current.actor = nil
  end

  def assert_download_allowed(kit)
    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 1
    assert_includes response.body, "Download kit"

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_response :redirect
    refute_equal 403, response.status
    refute_package_path(response.redirect_url)

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      post recording_studio_downloadable.recording_package_path(kit)
    end
    assert_response :redirect
    refute_equal 403, response.status

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_status_path(kit), as: :json
    end
    assert_response :success
    assert_equal true, response.parsed_body["ready"]
    assert_equal recording_studio_downloadable.recording_package_path(kit), response.parsed_body["download_url"]
  end

  def assert_download_refused(kit)
    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
    refute_includes response.body, "Download kit"

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_includes [401, 403], response.status
    assert_nil response.redirect_url

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      post recording_studio_downloadable.recording_package_path(kit)
    end
    assert_includes [401, 403], response.status

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_status_path(kit), as: :json
    end
    assert_includes [401, 403], response.status
  end

  def refute_package_path(url)
    assert_predicate url, :present?
    refute_match(%r{/recording_studio_downloadable/recordings/.+/package}, URI.parse(url).path)
  end

  def signed_blob_request_path(url)
    uri = URI.parse(url)
    return uri.request_uri if uri.host.blank? || uri.host == "www.example.com"

    url
  end
end
