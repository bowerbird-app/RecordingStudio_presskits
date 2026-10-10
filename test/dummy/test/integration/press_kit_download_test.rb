# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitDownloadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "kit-download-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Download Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "downloadable is enabled on press kits with the public kit action" do
    kit = record_kit("Spring launch")

    assert RecordingStudio.capability_enabled?(:downloadable, for: RecordingStudioPresskits::PressKit)
    assert kit.downloadable?
    assert_equal :"presskits.kit_download", kit.downloadable_action
    assert_equal :public, kit.downloadable_export_scope
    assert_equal :manifest, kit.downloadable_source
    defaults = RecordingStudioAccessible.configuration.action_audiences[:"presskits.kit_download"]
    assert_equal :granted, defaults[:default]
    assert_equal %i[download edit admin], defaults[:granted_roles]
  end

  test "manifest includes public kit text, cover, and section photos with unique names" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    kit.reload
    cover = place_cover!(kit, filename: "harbour-gallery.jpg", alt: "A white gallery hall", caption: "Hall", credit: "Pat")
    section = add_images_section(kit, title: "Press photos")
    photo = place_section_photo!(section, filename: "stage.jpg", alt: "The stage", caption: "Night", credit: "Sam")
    trashed = place_section_photo!(section, filename: "draft.jpg", alt: "Draft shot")
    trashed.recording_studio_trashable_trash!(actor: @user)
    add_text_section(kit, title: "The story", body: "<p>Private? No. This is the story.</p>")
    add_quote_section(kit)
    publish_kit!(kit, slug: "spring-launch-download")

    files = kit.recordable.downloadable_manifest
    names = files.map(&:filename)
    text = files.find { |file| file.filename == "kit.txt" }
    body = text.with_io(&:read)

    assert_includes names, "cover-harbour-gallery.jpg"
    assert_includes names, "press-photos-stage.jpg"
    refute_includes names, "draft.jpg"
    assert_equal names.uniq, names
    assert_includes body, "Spring launch"
    assert_includes body, "Doors at noon."
    assert_includes body, "The story"
    assert_includes body, "This is the story."
    assert_includes body, "A white gallery hall"
    assert_includes body, "Hall"
    assert_includes body, "Pat"
    assert_includes body, "The stage"
    assert_includes body, "Night"
    assert_includes body, "Sam"
    assert_includes body, "Doors at noon, bring coffee."
    assert_includes body, "Ada"
    refute_includes body, "Draft shot"
    refute_includes body, "draft.jpg"
    assert cover.present?
    assert photo.present?
  end

  test "unpublished kits are not downloadable and publish enqueues a build" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    refute kit.recordable.downloadable_available_for?(actor: @user, action: :"presskits.kit_download")

    assert_enqueued_jobs 1, only: RecordingStudioDownloadable::GeneratePackageJob do
      publish_kit!(kit, slug: "spring-launch-download-build")
    end
    kit.reload
    assert kit.currently_published?
    assert kit.recordable.downloadable_available_for?(actor: @user, action: :"presskits.kit_download")
    assert kit.downloadable_package.present?
  end

  test "unpublish invalidates the kit zip immediately" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    perform_enqueued_jobs do
      publish_kit!(kit, slug: "spring-launch-download-invalidate")
    end
    kit.reload
    package = kit.downloadable_package
    assert package.present?

    kit.reload
    assert kit.downloadable_ready?

    publish_kit!(kit, slug: "spring-launch-download-invalidate", status: "draft")
    kit.reload
    refute kit.currently_published?
    refute kit.recordable.downloadable_available_for?(actor: @user, action: :"presskits.kit_download")
    refute kit.downloadable_ready?
  end

  test "download button shows on the public kit for someone who can download" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    publish_kit!(kit, slug: "spring-launch-download-button")
    sign_in @user
    switch_to_root(@root)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 1
    assert_includes response.body, "Download kit"
    assert_includes response.body, "recording-studio-downloadable--package"
  end

  test "download button stays off previews and off the public kit for visitors" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    publish_kit!(kit, slug: "spring-launch-download-hidden")

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
    refute_includes response.body, "Download kit"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-download", count: 0

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    refute_includes css_select("#presskits-editor-preview").to_html, "presskits-kit-download"
  end

  test "a view-only person cannot download the kit zip" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    publish_kit!(kit, slug: "spring-launch-download-denied")
    viewer = User.create!(
      email: "view-only-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    result = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: viewer,
      role: :view,
      manager_actor: @user
    )
    raise result.error if result.failure?

    sign_in viewer
    Current.actor = viewer
    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_images_section(kit, title:)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Images",
      actor: @user,
      title: title
    )
  end

  def add_text_section(kit, title:, body:)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    @root.revise(content) { |text| text.body = body }
    section
  end

  def add_quote_section(kit)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::QuoteSection",
      actor: @user,
      title: "Quotes"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    content.record(RecordingStudioPresskits::Quote, actor: @user, parent_recording: content) do |quote|
      quote.body = "Doors at noon, bring coffee."
      quote.name = "Ada"
      quote.role = "Director"
      quote.organisation = "Harbour Studio"
    end
    section
  end

  def library_photo(filename, alt: nil, caption: nil, credit: nil)
    library = @root.image_library(actor: @user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: filename,
      content_type: "image/jpeg"
    )
    photo = library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
    attrs = { alt_text: alt, caption: caption, credit: credit }.compact
    photo.revise_attachment_metadata(actor: @user, **attrs) if attrs.any?
    photo
  end

  def place_cover!(kit, filename: "harbour-gallery.jpg", alt: "A white gallery hall", caption: nil, credit: nil)
    photo = library_photo(filename, alt: alt, caption: caption, credit: credit)
    kit.place_library_image(attachment_recording: photo, actor: @user)
    photo
  end

  def place_section_photo!(section, filename:, alt: nil, caption: nil, credit: nil)
    photo = library_photo(filename, alt: alt, caption: caption, credit: credit)
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    result = RecordingStudioPresskits::SectionImages.place(
      images_recording: content,
      attachment_recording: photo,
      actor: @user
    )
    raise result.error if result.failure?

    photo
  end

  def cover_fixture_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
  end

  def publish_kit!(kit, slug:, status: "published")
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: slug, status: status, meta_robots: "index,follow" }
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
