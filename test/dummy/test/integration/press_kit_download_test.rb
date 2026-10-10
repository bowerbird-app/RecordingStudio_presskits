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
    assert_equal :public, defaults[:default]
    assert_includes defaults[:allowed], :public
    assert_includes defaults[:allowed], :signed_in
    assert_includes defaults[:allowed], :granted
    refute_includes defaults[:allowed], :"presskits.verified_journalist"
    assert_equal %i[download edit admin], defaults[:granted_roles]
    assert_equal :edit, defaults[:manage_role]
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
    perform_enqueued_jobs do
      publish_kit!(kit, slug: "spring-launch-download-button")
    end
    sign_in @user
    switch_to_root(@root)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 1
    assert_includes response.body, "Download kit"
    assert_includes response.body, "recording-studio-downloadable--package"
  end

  test "anonymous visitors can download a published public kit" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    perform_enqueued_jobs do
      publish_kit!(kit, slug: "spring-launch-download-public")
    end
    Current.actor = nil

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 1
    assert_includes response.body, "Download kit"

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :redirect
    refute_equal 403, response.status
  end

  test "download button stays off previews and the editor" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    perform_enqueued_jobs do
      publish_kit!(kit, slug: "spring-launch-download-hidden")
    end

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-download", count: 0

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    refute_includes css_select("#presskits-editor-preview").to_html, "presskits-kit-download"
    assert_select "#presskits-downloads", text: "Downloads"
    assert_select "#presskits-downloads [data-flat-pack--icon-name-value='arrow-down-tray']"
  end

  test "signed_in audience blocks anonymous download" do
    kit = restrict_downloads!(
      record_kit("Spring launch"),
      audience: :signed_in,
      slug: "spring-launch-download-signed-in"
    )
    Current.actor = nil

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
    refute_includes response.body, "Download kit"

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden
  end

  test "granted audience blocks visitors without a download grant" do
    kit = restrict_downloads!(
      record_kit("Spring launch"),
      audience: :granted,
      slug: "spring-launch-download-denied"
    )
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

    Current.actor = nil
    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0

    sign_in viewer
    Current.actor = viewer
    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 0
  end

  test "a view-only person can download a public kit" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    perform_enqueued_jobs do
      publish_kit!(kit, slug: "spring-launch-download-view")
    end
    viewer = User.create!(
      email: "view-public-#{SecureRandom.hex(4)}@example.com",
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
    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-download", count: 1

    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :redirect
  end

  test "downloads editor lists allowed audiences and defaults to public" do
    kit = record_kit("Spring launch")
    assert_equal :public, RecordingStudioPresskits::KitDownload.effective_audience(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    downloads_path = recording_studio_presskits.edit_press_kit_downloads_path(kit)
    visibility_path = recording_studio_presskits.edit_press_kit_visibility_path(kit)
    assert_select "#presskits-visibility[href='#{visibility_path}']", text: "Visibility"
    assert_select "#presskits-visibility [data-flat-pack--icon-name-value='eye']"
    assert_select "#presskits-downloads[href='#{downloads_path}']", text: "Downloads"
    assert_select "#presskits-downloads [data-flat-pack--icon-name-value='arrow-down-tray']"
    toolbar_html = css_select("#presskits-editor-toolbar").to_html
    assert_operator toolbar_html.index("presskits-visibility"), :<, toolbar_html.index("presskits-downloads")

    get downloads_path, headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_select "h1", text: "Downloads"
    assert_select "[data-fp-screen][data-title='\u200B']"
    assert_select "p", text: "Who can download this press kit"
    assert_select "#presskits-downloads-audience[aria-label='Who can download this press kit']"
    refute_select "legend", text: "Who can download this press kit"
    refute_select "label", text: "Who can download this press kit"
    refute_select "select[name='downloads[audience]']"
    assert_select "input[type='radio'][name='downloads[audience]'][value='public'][checked]"
    assert_select "input[type='radio'][name='downloads[audience]'][value='signed_in']"
    assert_select "input[type='radio'][name='downloads[audience]'][value='granted']"
    refute_select "input[type='radio'][name='downloads[audience]'][value='presskits.verified_journalist']"
    refute_select "input[type='radio'][name='downloads[audience]'][value='presskits.test_custom']"
    assert_select "#presskits-downloads-audience [data-flat-pack--icon-name-value='globe-alt']"
    assert_select "#presskits-downloads-audience [data-flat-pack--icon-name-value='user']"
    assert_select "#presskits-downloads-audience [data-flat-pack--icon-name-value='lock-closed']"
    refute_select "#presskits-downloads-audience [data-flat-pack--icon-name-value='user-group']"
    refute_includes response.body, "Your workspace only allows some of these choices"
  end

  test "downloads editor lists a test-only custom audience when the host registers one" do
    kit = record_kit("Spring launch")
    with_test_custom_download_audience do
      sign_in @user
      switch_to_root(@root)
      get recording_studio_presskits.edit_press_kit_downloads_path(kit),
          headers: { "Turbo-Frame" => "pk-editor-screen" }
      assert_response :success
      assert_select "input[type='radio'][name='downloads[audience]'][value='presskits.test_custom']"
      assert_select "#presskits-downloads-audience [data-flat-pack--icon-name-value='user-group']"
    end
  end

  test "kit editors can save who may download" do
    kit = record_kit("Spring launch")
    editor = User.create!(
      email: "kit-editor-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    result = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: editor,
      role: :edit,
      manager_actor: @user
    )
    raise result.error if result.failure?

    sign_in editor
    Current.actor = editor
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_downloads_path(kit), params: {
      downloads: { audience: "signed_in" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_equal :signed_in, RecordingStudioPresskits::KitDownload.effective_audience(kit.reload)
  end

  test "a view-only person cannot open the downloads setting" do
    kit = record_kit("Spring launch")
    viewer = User.create!(
      email: "view-downloads-#{SecureRandom.hex(4)}@example.com",
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
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_response :forbidden
  end

  test "host allowed list falls back to granted and the editor shows that audience" do
    audiences = RecordingStudioAccessible.configuration.action_audiences
    previous = audiences[:"presskits.kit_download"]
    kit = restrict_downloads!(record_kit("Spring launch"), audience: :signed_in, slug: "spring-host-download")
    audiences[:"presskits.kit_download"] = previous.merge(allowed: %i[granted])

    assert_equal :granted, RecordingStudioPresskits::KitDownload.effective_audience(kit.reload)
    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_response :success
    assert_select "input[type='radio'][name='downloads[audience]'][value='granted'][checked]"
    refute_select "input[type='radio'][name='downloads[audience]'][value='public']"
    refute_select "input[type='radio'][name='downloads[audience]'][value='signed_in']"
    assert_includes response.body, "Your workspace only allows some of these choices"
  ensure
    RecordingStudioAccessible.configuration.action_audiences[:"presskits.kit_download"] = previous if previous
  end

  test "workspace constraint falls back to granted and the editor shows that audience" do
    kit = restrict_downloads!(
      record_kit("Spring launch"),
      audience: :signed_in,
      slug: "spring-constrained-download"
    )

    RecordingStudioAccessible.set_audience_constraint!(
      root: @root,
      action: :"presskits.kit_download",
      allowed_audiences: %i[granted],
      actor: @user
    )

    assert_equal :granted, RecordingStudioPresskits::KitDownload.effective_audience(kit.reload)
    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_response :success
    assert_select "input[type='radio'][name='downloads[audience]'][value='granted'][checked]"
    refute_select "input[type='radio'][name='downloads[audience]'][value='public']"
    refute_select "input[type='radio'][name='downloads[audience]'][value='signed_in']"
    assert_includes response.body, "Your workspace only allows some of these choices"
  end

  private

  TEST_CUSTOM_AUDIENCE = :"presskits.test_custom"

  def with_test_custom_download_audience
    previous = nil
    unless RecordingStudioAccessible.registered_audience?(TEST_CUSTOM_AUDIENCE)
      RecordingStudioAccessible.register_audience(TEST_CUSTOM_AUDIENCE) { |**_kwargs| false }
    end

    audiences = RecordingStudioAccessible.configuration.action_audiences
    previous = audiences[:"presskits.kit_download"]
    audiences[:"presskits.kit_download"] = previous.merge(
      allowed: Array(previous[:allowed]) | [TEST_CUSTOM_AUDIENCE]
    )
    yield
  ensure
    if previous
      RecordingStudioAccessible.configuration.action_audiences[:"presskits.kit_download"] = previous
    end
  end

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

  def restrict_downloads!(kit, audience:, slug:)
    place_cover!(kit)
    perform_enqueued_jobs do
      publish_kit!(kit, slug: slug)
    end
    RecordingStudioPresskits::KitDownload.set_audience!(
      recording: kit,
      audience: audience,
      actor: @user
    )
    kit.reload
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
