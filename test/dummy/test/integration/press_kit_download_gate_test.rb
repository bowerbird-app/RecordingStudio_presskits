# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitDownloadGateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "kit-gate-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Gate Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
    Current.download_gate = nil
  end

  test "the gate is registered for kit and images downloads" do
    kit_gate = RecordingStudioDownloadable.configuration.download_gate_for(:"presskits.kit_download")
    images_gate = RecordingStudioDownloadable.configuration.download_gate_for(:"presskits.images_download")

    assert_equal RecordingStudioPresskits::KitDownloadGate, kit_gate
    assert_equal RecordingStudioPresskits::KitDownloadGate, images_gate
    images = RecordingStudioAccessible.configuration.action_audiences[:"presskits.images_download"]
    assert_equal :public, images[:default]
    assert_includes images[:granted_roles], :view
  end

  test "an unsatisfied kit download redirects and a json get returns the continuation" do
    kit = publish_downloadable_kit!("spring-gate-hold")
    Current.actor = nil

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_redirected_to recording_studio_presskits.download_gate_path(recording_id: kit.id)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "What do you want to use this content for?"
    assert_includes response.body, "Editorial consideration"
    assert_includes response.body, "Publish immediately"
    assert_select "input[type=radio][name=purpose][value=editorial][required]"
    assert_select "input[type=radio][name=purpose][value=publish][required]"
    assert_select "[data-flat-pack--icon-name-value=newspaper]"
    assert_select "[data-flat-pack--icon-name-value=bolt]"
    refute_includes response.body, "Send me the files"
    assert_includes response.body, "Continue"

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit), as: :json
    end
    assert_response :conflict
    assert_equal(
      recording_studio_presskits.download_gate_path(recording_id: kit.id),
      response.parsed_body["continuation_url"]
    )
    assert_empty RecordingStudioDownloadable::DownloadLog.where(recording_id: kit.id)
  end

  test "choosing a purpose starts the kit zip and logs that purpose" do
    kit = publish_downloadable_kit!("spring-gate-yes")
    Current.actor = nil

    patch recording_studio_presskits.download_gate_path, params: { recording_id: kit.id }
    assert_redirected_to recording_studio_presskits.download_gate_path(recording_id: kit.id)
    follow_redirect!
    assert_includes response.body, "Pick one to continue."

    get recording_studio_downloadable.recording_package_path(kit)
    assert_redirected_to recording_studio_presskits.download_gate_path(recording_id: kit.id)

    patch recording_studio_presskits.download_gate_path, params: { recording_id: kit.id, purpose: "publish" }
    assert_redirected_to recording_studio_presskits.download_gate_path(recording_id: kit.id)

    assert_no_enqueued_jobs only: RecordingStudioDownloadable::GeneratePackageJob do
      get recording_studio_downloadable.recording_package_path(kit)
    end
    assert_response :redirect
    refute_match(%r{/download_gate}, response.redirect_url)

    log = RecordingStudioDownloadable::DownloadLog.where(recording_id: kit.id).last
    assert_equal({ "purpose" => "publish" }, log.metadata)
    assert_equal "presskits.kit_download", log.action
  end

  test "one purpose unlocks the images zip too" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit, title: "Press photos")
    content = section_content(section)
    attach_image!(content, "section-only.jpg")
    publish_kit!(kit, slug: "spring-gate-images")
    assert_equal "press-photos", content.recordable.name
    Current.actor = nil

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-cover-download]", count: 1
    assert_select "[data-images-download]", text: "Download all images"
    assert_select "#download-gate-modal-#{kit.id}"
    assert_select "#download-gate-modal-#{content.id}"
    assert_select "#download-gate-modal-#{kit.id} input[name=purpose][value=editorial]"
    assert_select "#download-gate-modal-#{content.id} input[name=purpose][value=publish]"
    assert_includes response.body, "What do you want to use this content for?"
    refute_includes response.body, "Send me the files"

    patch recording_studio_presskits.download_gate_path, params: { recording_id: kit.id, purpose: "editorial" }

    get recording_studio_downloadable.recording_package_path(content)
    assert_response :redirect
    refute_match(%r{/download_gate}, response.redirect_url)
  end

  test "people with access still pass the gate and a denied visitor sees no button" do
    kit = publish_downloadable_kit!("spring-gate-locked")
    RecordingStudioPresskits::KitDownload.set_audience!(recording: kit, audience: :granted, actor: @user)
    Current.actor = nil

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-cover-download]", count: 0

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden

    sign_in @user
    Current.actor = @user
    get kit.publishable_public_path
    assert_select "[data-cover-download]", count: 1
    get recording_studio_downloadable.recording_package_path(kit)
    assert_redirected_to recording_studio_presskits.download_gate_path(recording_id: kit.id)
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def publish_downloadable_kit!(slug)
    kit = record_kit("Spring launch")
    attach_image!(kit, "harbour-gallery.jpg")
    publish_kit!(kit, slug: slug)
    assert kit.downloadable_ready?
    kit
  end

  def publish_kit!(kit, slug:)
    perform_enqueued_jobs do
      result = RecordingStudioPublishable::Services::Publishables::Update.call(
        parent_recording: kit,
        actor: @user,
        attributes: { slug: slug, status: "published", meta_robots: "index,follow" }
      )
      raise result.error if result.failure?
    end
    kit.reload
  end

  def add_images_section(kit, title:)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Images",
      actor: @user,
      title: title
    )
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def attach_image!(parent, filename)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")),
      filename: filename,
      content_type: "image/jpeg"
    )
    parent.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user, name: File.basename(filename, ".*"))
  end
end
