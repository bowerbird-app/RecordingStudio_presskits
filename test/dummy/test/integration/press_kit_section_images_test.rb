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

  test "picker screen reuses Attachable picker UI inside pk-editor and places many photos" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    first = library_photo("one.jpg", alt: "One")
    second = library_photo("two.jpg", alt: "Two")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kit_section_library_images_path(kit, section),
        headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_includes response.body, "Add from library"
    assert_includes response.body, "recording-studio-attachable--attachment-image-picker"
    assert_includes response.body, "recording-studio-presskits--library-picker"
    assert_includes response.body, "multiple-selection-value=\"true\""
    refute_includes response.body, "openSinglePicker"
    refute_includes response.body, "library-placement-picker"

    post recording_studio_presskits.press_kit_section_library_images_path(kit, section), params: {
      attachment_recording_ids: [first.id, second.id]
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    content = section_content(section)
    assert_equal [first.id, second.id], content.library_placements.map { |item| item.attachment_recording.id }

    post recording_studio_presskits.press_kit_section_library_images_path(kit, section), params: {
      attachment_recording_ids: [first.id]
    }
    follow_redirect!
    assert_equal 2, content.reload.library_placements.size
    assert_includes response.body, "already in this section"
  end

  test "upload writes the photo into the library then places it" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    sign_in @user
    switch_to_root(@root)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: "upload.jpg",
      content_type: "image/jpeg"
    )
    assert_difference -> { library_image_count }, 1 do
      post recording_studio_presskits.press_kit_section_library_images_path(kit, section), params: {
        signed_blob_id: blob.signed_id
      }
    end
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    content = section_content(section)
    assert_equal 1, content.library_placements.size
    photo = content.library_placements.first.attachment_recording
    assert_equal @root, photo.root_recording
    assert_equal "RecordingStudioAttachable::Library", photo.parent_recording.recordable_type
  end

  test "upload accepts a multipart file and lands it in the library" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    sign_in @user
    switch_to_root(@root)

    file = Rack::Test::UploadedFile.new(cover_fixture_path.to_s, "image/jpeg")
    assert_difference -> { library_image_count }, 1 do
      post recording_studio_presskits.press_kit_section_library_images_path(kit, section), params: {
        file: file
      }
    end
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_equal 1, section_content(section).library_placements.size
  end

  test "remove from the kit keeps the library photo" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    photo = place_photo!(section, "keep.jpg")
    placement = section_content(section).library_placements.first.placement_recording
    sign_in @user
    switch_to_root(@root)

    delete recording_studio_presskits.press_kit_section_library_image_path(kit, section, placement)
    follow_redirect!

    assert_empty section_content(section).reload.library_placements
    assert_nil photo.reload.trashed_at
    assert @root.image_library(actor: @user).images(per_page: 20).map(&:id).include?(photo.id)
  end

  test "reorder keeps placement order on the public kit" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    first = place_photo!(section, "first.jpg", alt: "First")
    second = place_photo!(section, "second.jpg", alt: "Second")
    content = section_content(section)
    placements = content.library_placements.map(&:placement_recording)
    content.reorder_library_placements!(
      ordered_recording_ids: [placements.last.id, placements.first.id],
      actor: @user
    )
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    body = response.body
    assert_operator body.index("alt=\"Second\""), :<, body.index("alt=\"First\"")
    assert_equal [second.id, first.id], content.reload.library_placements.map { |item| item.attachment_recording.id }
  end

  test "a photo from another workspace is refused" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    outsider = other_workspace_photo
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_section_library_images_path(kit, section), params: {
      attachment_recording_ids: [outsider.id]
    }
    follow_redirect!

    assert_empty section_content(section).library_placements
    refute_includes response.body, "Photo added."
  end

  test "public kit and preview skip a trashed library photo" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    live = place_photo!(section, "live.jpg", alt: "Live hall")
    gone = place_photo!(section, "gone.jpg", alt: "Gone hall")
    gone.recording_studio_trashable_trash!(actor: @user) if gone.respond_to?(:recording_studio_trashable_trash!)
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
    assert_equal [live.id], section_content(section).library_placements.map { |item| item.attachment_recording.id }
  end

  test "the same photo may sit in two sections" do
    kit = record_kit("Spring launch")
    first = add_images_section(kit)
    second = add_images_section(kit, title: "More photos")
    photo = library_photo("shared.jpg")
    RecordingStudioPresskits::SectionImages.place(
      images_recording: section_content(first),
      attachment_recording: photo,
      actor: @user
    )
    result = RecordingStudioPresskits::SectionImages.place(
      images_recording: section_content(second),
      attachment_recording: photo,
      actor: @user
    )

    assert result.success?
    assert_equal 1, section_content(first).library_placements.size
    assert_equal 1, section_content(second).library_placements.size
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

  def library_photo(filename, alt: nil)
    library = @root.image_library(actor: @user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: filename,
      content_type: "image/jpeg"
    )
    photo = library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
    photo.revise_attachment_metadata(actor: @user, alt_text: alt) if alt
    photo
  end

  def place_photo!(section, filename, alt: nil)
    photo = library_photo(filename, alt: alt || File.basename(filename, ".*"))
    result = RecordingStudioPresskits::SectionImages.place(
      images_recording: section_content(section),
      attachment_recording: photo,
      actor: @user
    )
    raise result.error if result.failure?

    photo
  end

  def other_workspace_photo
    other_user = User.create!(
      email: "other-images-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    other_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"))
    RecordingStudioAccessible.bootstrap_owner_access!(recording: other_root, actor: other_user)
    previous = Current.actor
    Current.actor = other_user
    library = other_root.image_library(actor: other_user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: "outsider.jpg",
      content_type: "image/jpeg"
    )
    library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: other_user)
  ensure
    Current.actor = previous
  end

  def library_image_count
    @root.image_library(actor: @user).images(per_page: 50).size
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
