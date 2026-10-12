# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitSectionImagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "section-images-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Section Images Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "upload attaches a photo on the images section" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    sign_in @user
    switch_to_root(@root)

    file = Rack::Test::UploadedFile.new(cover_fixture_path.to_s, "image/jpeg", true, original_filename: "upload.jpg")
    post recording_studio_attachable.recording_attachment_imports_path(content), params: {
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_section_path(kit, section),
      attachment_import: { attachments: [{ file: file }] }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!

    photos = RecordingStudioPresskits::DirectImages.list(content.reload)
    assert_equal 1, photos.size
    assert_equal content, photos.first.parent_recording
    assert_equal "upload.jpg", photos.first.recordable.original_filename
    assert_equal @root, photos.first.root_recording
  end

  test "upload accepts a signed blob on the images section" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    sign_in @user
    switch_to_root(@root)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: "signed.jpg",
      content_type: "image/jpeg"
    )

    post recording_studio_attachable.recording_attachment_imports_path(content), params: {
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_section_path(kit, section),
      attachment_import: { attachments: [{ signed_blob_id: blob.signed_id }] }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)

    photos = RecordingStudioPresskits::DirectImages.list(content.reload)
    assert_equal ["signed.jpg"], photos.map { |photo| photo.recordable.original_filename }
  end

  test "caption credit and alt save on the attachment" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    photo = attach_image!(content, "stage.jpg", alt: "stage")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    signed = css_select("input[name='attachment_collection[signed_editor]']").first["value"]
    return_to = recording_studio_presskits.edit_press_kit_section_path(kit, section)
    patch recording_studio_attachable.recording_attachment_collection_path(content), params: {
      redirect_mode: "return_to",
      return_to: return_to,
      attachment_collection: {
        signed_editor: signed,
        rows: [{
          recording_id: photo.id,
          caption: "Stage left",
          credit: "Ada",
          alt_text: "The stage"
        }]
      }
    }
    assert_response :redirect
    follow_redirect!
    photo.reload
    assert_equal "Stage left", photo.recordable.caption
    assert_equal "Ada", photo.recordable.credit
    assert_equal "The stage", photo.recordable.alt_text
  end

  test "reorder keeps attachment order on the public kit" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    first = attach_image!(content, "first.jpg", alt: "First")
    second = attach_image!(content, "second.jpg", alt: "Second")
    content.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    body = response.body
    assert_operator body.index("alt=\"Second\""), :<, body.index("alt=\"First\"")
    assert_equal [second.id, first.id], RecordingStudioPresskits::DirectImages.list(content.reload).map(&:id)
  end

  test "trashing an attachment removes it from the public kit and the editor" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    live = attach_image!(content, "live.jpg", alt: "Live hall")
    gone = attach_image!(content, "gone.jpg", alt: "Gone hall")
    gone.recording_studio_trashable_trash!(actor: @user)
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "img[alt='Live hall']"
    assert_select "img[alt='Gone hall']", count: 0

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-editor-preview img[alt='Live hall']"
    assert_select "#presskits-editor-preview img[alt='Gone hall']", count: 0
    assert_equal [live.id], RecordingStudioPresskits::DirectImages.list(content.reload).map(&:id)
  end

  test "remove trashes the attachment" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    photo = attach_image!(content, "keep.jpg")
    sign_in @user
    switch_to_root(@root)
    return_to = recording_studio_presskits.edit_press_kit_section_path(kit, section)

    delete recording_studio_attachable.destroy_attachment_path(
      photo,
      redirect_mode: "return_to",
      return_to: return_to
    )
    assert_redirected_to return_to
    follow_redirect!

    assert photo.reload.trashed_at
    assert_empty RecordingStudioPresskits::DirectImages.list(content.reload)
  end

  test "a duplicated kit gets independent image copies" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit, title: "Press photos")
    content = section_content(section)
    photo = attach_image!(content, "shared.jpg", alt: "Hall", caption: "Doors")
    attach_image!(kit, "cover.jpg", alt: "Cover hall")

    copy = kit.duplicate_in_place!(actor: @user)
    copy_section = RecordingStudioPresskits::KitQuery.sections_for(copy).find do |item|
      section_content(item)&.recordable.is_a?(RecordingStudioPresskits::Images)
    end
    copy_content = section_content(copy_section)
    copy_photo = RecordingStudioPresskits::DirectImages.list(copy_content).first
    copy_cover = RecordingStudioPresskits::DirectImages.list(copy).first

    refute_equal photo.id, copy_photo.id
    refute_equal photo.recordable.file.blob.id, copy_photo.recordable.file.blob.id
    refute_equal kit.id, copy.id
    assert copy_cover
    refute_equal RecordingStudioPresskits::DirectImages.list(kit).first.recordable.file.blob.id,
                 copy_cover.recordable.file.blob.id

    copy_photo.revise_attachment_metadata(actor: @user, caption: "Changed", alt_text: "Changed alt")
    photo.reload
    assert_equal "Doors", photo.recordable.caption
    assert_equal "Hall", photo.recordable.alt_text

    copy_photo.remove_attachment(actor: @user)
    assert photo.reload.recordable.file.attached?
    assert_nil photo.trashed_at
    assert_empty RecordingStudioPresskits::DirectImages.list(copy_content.reload)
    assert_equal [photo.id], RecordingStudioPresskits::DirectImages.list(content.reload).map(&:id)
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_images_section(kit, title: "Images")
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

  def attach_image!(parent, filename, alt: nil, caption: nil, credit: nil)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: filename,
      content_type: "image/jpeg"
    )
    photo = parent.record_attachment_upload(
      signed_blob_id: blob.signed_id,
      actor: @user,
      name: File.basename(filename, ".*")
    )
    attrs = { alt_text: alt, caption: caption, credit: credit }.compact
    photo.revise_attachment_metadata(actor: @user, **attrs) if attrs.any?
    photo
  end

  def cover_fixture_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-section-images-#{SecureRandom.hex(4)}", status: "published" }
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
