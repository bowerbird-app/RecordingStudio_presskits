# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitCoverImageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "cover-image-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Cover Image Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "card and grid hide a cover image when the kit has no attachment" do
    kit = record_kit("Spring launch")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-image]", count: 0
    assert_select "#presskits-kit-cover [data-cover-fallback]"
    assert_select "#presskits-kit-cover [data-cover-eyebrow]", text: "Press kit"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-image]", count: 0
    assert_select "[data-cover-card] [data-cover-fallback]", minimum: 1
    assert_select "[data-cover-card] [data-cover-tag]", text: "Press kit"
  end

  test "public kit and editor show a direct cover attachment on the card" do
    kit = record_kit("Spring launch")
    photo = attach_cover!(kit)
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-image] img[alt='A white gallery hall']"
    card = css_select("#presskits-kit-cover").first.to_html
    assert_operator card.index("data-cover-image"), :<, card.index("Spring launch")
    assert_includes card, "@container"
    assert_includes css_select("#presskits-kit-cover [data-cover-frame]").first["class"], "aspect-[430/368]"
    refute_includes card, "aspect-[1440/640]"
    refute_select "#presskits-cover-hero"
    assert_select "#presskits-kit-cover [data-cover-eyebrow]", text: "Press kit"
    assert_select "#presskits-kit-cover [data-cover-title]", text: "Spring launch"
    refute_select "[data-presskits-header-image-actions]"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-header [data-cover-image] img[alt='A white gallery hall']"
    assert_select "#presskits-kit-header [data-cover-card]"
    refute_select "#presskits-kit-header #presskits-cover-image"
    assert_select "#presskits-kit-header [data-presskits-header-image-actions] a[aria-label='Edit image'][href='#{header_cover_path(kit)}']"
    refute_select "#presskits-kit-header [role='menuitem'][aria-label='Cover image']"
    refute_includes response.body, recording_studio_attachable.recording_placements_path(kit)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-card] [data-cover-image] img[alt='A white gallery hall']"
    card = css_select("[data-cover-card]").first.to_html
    assert_operator card.index("data-cover-image"), :<, card.index("Spring launch")
    refute_includes card, "aspect-[9/16]"
    assert_includes card, "object-cover"
    assert_equal photo.id, RecordingStudioPresskits::DirectImages.list(kit).first.id
  end

  test "header editor uploads and removes a cover image and stays off the 9/16 preview" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "#press_kit_cover_image button", text: "Upload"
    refute_select "#presskits-header-edit-preview"
    refute_select "[data-cover-ratio='9 / 16']"
    refute_includes response.body, "Choose from the library"
    refute_includes response.body, "recording-studio-attachable--library-placement"

    file = Rack::Test::UploadedFile.new(cover_fixture_path.to_s, "image/jpeg", true, original_filename: "harbour-gallery.jpg")
    post recording_studio_attachable.recording_attachment_imports_path(kit), params: {
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_header_path(kit),
      attachment_import: { attachments: [{ file: file }] }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    follow_redirect!
    assert_select "#press_kit_cover_image button", text: "Change"
    assert_select "#press_kit_cover_image a", text: "Remove"
    refute_select "#presskits-header-edit-preview"
    photo = RecordingStudioPresskits::DirectImages.list(kit.reload).first
    assert_equal "harbour-gallery.jpg", photo.recordable.original_filename

    delete recording_studio_attachable.destroy_attachment_path(
      photo,
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_header_path(kit)
    )
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    follow_redirect!
    assert_select "#press_kit_cover_image button", text: "Upload"
    assert_empty RecordingStudioPresskits::DirectImages.list(kit.reload)
  end

  test "reordering sections leaves the cover attachment on the kit" do
    kit = record_kit("Spring launch")
    first = record_block(kit, "Hero")
    second = record_block(kit, "Notes")
    photo = attach_cover!(kit)
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      ordered_recording_ids: [second.id, first.id]
    }
    follow_redirect!

    assert_response :success
    sections = RecordingStudioPresskits::KitQuery.sections_for(kit)
    assert_equal [second.id, first.id], sections.map(&:id)
    refute_includes sections.map(&:id), photo.id
    assert_equal [photo.id], RecordingStudioPresskits::DirectImages.list(kit.reload).map(&:id)
  end

  private

  test "press kits index published filter keeps only published kits" do
    publish_kit!(record_kit("Filter published kit"))
    record_kit("Filter draft kit")

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.press_kits_path(published: "1", view: "table")
    assert_response :success
    assert_includes response.body, "Filter published kit"
    refute_includes response.body, "Filter draft kit"
    assert_includes response.body, "published=1"

    get recording_studio_presskits.press_kits_path(publish_from: 1.day.from_now.to_date.iso8601)
    assert_response :success
    refute_includes response.body, "Filter published kit"

    get recording_studio_presskits.press_kits_path(publish_from: "bad")
    assert_response :success
    assert_includes response.body, "Filter draft kit"
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      actor: @user,
      title: title
    )
  end

  def attach_cover!(kit)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: "harbour-gallery.jpg",
      content_type: "image/jpeg"
    )
    photo = kit.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user, name: "Harbour Gallery")
    photo.revise_attachment_metadata(actor: @user, alt_text: "A white gallery hall")
    photo
  end

  def cover_fixture_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
  end

  def header_cover_path(kit)
    "#{recording_studio_presskits.edit_press_kit_header_path(kit)}#press_kit_cover_image"
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-cover-image-#{SecureRandom.hex(4)}", status: "published" }
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
