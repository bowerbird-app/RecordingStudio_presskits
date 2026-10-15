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

  test "the public gallery keeps natural ratios and reveals the rest in the frame" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit, title: "Images", subtitle: "Credit the studio.")
    content = section_content(section)
    13.times { |index| attach_image!(content, "shot-#{index}.jpg", alt: "Shot #{index}") }
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    frame = "turbo-frame[id='presskits-images-#{content.id}']"
    masonry = css_select("#{frame} .fp-masonry").first
    assert_includes masonry["class"], "columns-1"
    assert_includes masonry["class"], "md:columns-2"
    assert_includes masonry["class"], "lg:columns-4"
    assert_includes masonry["class"], "fp-masonry--columns"
    assert_select "#{frame} .fp-masonry img", count: 12
    assert_select "a", text: "Download all images"
    assert_select "a", text: "Show more images (13)"
    heading = css_select("h2").find { |node| node.text == "Images" }
    assert_equal "Images", heading.text
    row = heading.parent
    badge = row.css("span.shrink-0").find { |node| node.text.strip == "13" }
    assert badge
    assert_equal "Copy link to Images", row.at_css("a")["aria-label"]
    refute_includes row.at_css("a").text, "13"
    meta = "JPG · 64×28 · 16:7"
    tile = css_select("#{frame} .fp-masonry__item").first
    overlay = tile.at_css("[data-fp-placement='bottom_left']")
    assert_equal "sm", overlay["data-fp-inset"]
    assert_equal meta, overlay.text.strip
    name = tile.element_children.find { |child| child.name == "span" }
    assert_equal "shot-0", name.text.strip
    refute_includes name.text, meta
    refute_includes response.body, "shot-0 · #{meta}"
    assert_select "#{frame} figcaption", count: 0
    assert_includes response.body, "Credit the studio."
    refute_includes response.body, "aspect-video"

    get kit.publishable_public_path, params: { images: content.id }
    assert_response :success
    assert_select "#{frame} .fp-masonry img", count: 13
    assert_select "a", text: "Show more images (13)", count: 0

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-editor-preview .fp-masonry img", count: 12
    assert_select "#presskits-editor-preview [data-fp-placement='bottom_left']", text: "JPG · 64×28 · 16:7"
    assert_select "#presskits-editor-preview a", text: "Show more images (13)"
    images_section = css_select("#presskits-editor-preview section").find do |node|
      node.at_css("[name='kit_section[title]'][value='Images']")
    end
    assert images_section
    assert_select images_section, "span", text: "13", count: 0
  end

  test "each images section opens its own lightbox on the clicked photo" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit, title: "Press photos")
    other = add_images_section(kit, title: "Extra")
    content = section_content(section)
    extra = section_content(other)
    13.times { |index| attach_image!(content, "shot-#{index}.jpg", alt: "Shot #{index}") }
    attach_image!(extra, "extra.jpg", alt: "Extra photo")

    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_section_lightbox(content, visible: 12, total: 13)
    assert_section_lightbox(extra, visible: 1, total: 1)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-editor-preview turbo-frame[id='presskits-images-#{content.id}'] button[data-flat-pack-lightbox-index='2']"
    assert_section_lightbox(content, visible: 12, total: 13)

    publish_kit!(kit)
    get kit.publishable_public_path
    assert_response :success
    assert_section_lightbox(content, visible: 12, total: 13)
    assert_select "turbo-frame[id='presskits-images-#{content.id}'] [data-flat-pack-lightbox-stage='true'] img[alt='Shot 12']"
    assert_select "turbo-frame[id='presskits-images-#{content.id}'] .fp-masonry img[alt='Shot 12']", count: 0

    get kit.publishable_public_path, params: { images: content.id }
    assert_response :success
    assert_section_lightbox(content, visible: 13, total: 13)
  end

  test "download all images zips this section only" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit, title: "Images")
    content = section_content(section)
    attach_image!(content, "section-only.jpg", alt: "Section only")
    attach_image!(kit, "cover-only.jpg", alt: "Cover only")
    publish_kit!(kit)

    get recording_studio_presskits.image_archive_path(content)
    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_includes response.headers["Content-Disposition"], "images.zip"
    names = Zip::File.open_buffer(response.body).map(&:name)
    assert_equal ["section-only.jpg"], names
  end

  test "a draft kit does not hand out the section zip" do
    kit = record_kit("Spring launch")
    section = add_images_section(kit)
    content = section_content(section)
    attach_image!(content, "draft.jpg", alt: "Draft")

    get recording_studio_presskits.image_archive_path(content)
    assert_response :not_found
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

  def assert_section_lightbox(content, visible:, total:)
    frame = "turbo-frame[id='presskits-images-#{content.id}']"
    group = "images#{content.id}"
    dialog = css_select("#{frame} dialog[data-controller='flat-pack--lightbox']").first
    assert dialog, "expected a lightbox for images #{content.id}"
    assert_equal group, dialog["data-flat-pack--lightbox-group-value"]
    assert_select "#{frame} .fp-masonry button[data-flat-pack-lightbox-group='#{group}']", count: visible
    visible.times do |index|
      button = css_select("#{frame} .fp-masonry button[data-flat-pack-lightbox-index='#{index}']").first
      assert button, "expected thumbnail #{index}"
      assert_equal "button", button["type"]
      assert_equal group, button["data-flat-pack-lightbox-group"]
    end
    assert_select "#{frame} .fp-masonry img", count: visible
    if total > 1
      assert_select "#{frame} [data-flat-pack--carousel-target='thumb']", count: total
    else
      assert_select "#{frame} [data-flat-pack--carousel-target='thumb']", count: 0
    end
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_images_section(kit, title: "Images", subtitle: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Images",
      actor: @user,
      title: title,
      subtitle: subtitle
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
