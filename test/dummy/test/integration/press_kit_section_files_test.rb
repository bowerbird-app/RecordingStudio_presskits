# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "zip"

class PressKitSectionFilesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "section-files-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Section Files Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "a kit can hold more than one files section" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit), params: {
      type: "RecordingStudioPresskits::Files",
      title: "Documents"
    }
    assert_response :redirect
    post recording_studio_presskits.press_kit_sections_path(kit), params: {
      type: "RecordingStudioPresskits::Files",
      title: "Documents"
    }
    assert_response :redirect

    sections = RecordingStudioPresskits::KitQuery.sections_for(kit.reload)
    assert_equal 2, sections.size
    assert sections.all? { |section| section_content(section).recordable.is_a?(RecordingStudioPresskits::Files) }
  end

  test "upload attaches a document and the editor shows its name extension and size" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit, title: "Documents", subtitle: "For the desk")
    content = section_content(section)
    sign_in @user
    switch_to_root(@root)

    post recording_studio_attachable.recording_attachment_imports_path(content), params: {
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_section_path(kit, section),
      attachment_import: { attachments: [{ file: uploaded("one-sheet.pdf", "application/pdf", "%PDF-1.1\n%%EOF\n") }] }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!

    files = RecordingStudioPresskits::DirectFiles.list(content.reload)
    assert_equal 1, files.size
    assert_equal "one-sheet.pdf", files.first.recordable.original_filename
    assert_equal "one-sheet", files.first.recordable.name
    assert_select "[data-presskits-file-editor='#{files.first.id}']"
    assert_select "[data-presskits-file-meta]", text: /PDF/
    assert_select "a[href*='attachments/#{files.first.id}/download']", count: 0
    assert_select "a[href*='attachments/#{files.first.id}/file']", count: 0
  end

  test "name and description save on the attachment" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit)
    content = section_content(section)
    file = attach_file!(content, "bios.txt", "text/plain", "Bios\n", "Bios")
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
          recording_id: file.id,
          name: "Director bios",
          description: "The long version.",
          order: "1"
        }]
      }
    }
    assert_response :redirect
    follow_redirect!
    file.reload
    assert_equal "Director bios", file.recordable.name
    assert_equal "The long version.", file.recordable.description
  end

  test "reorder keeps file order on the public kit" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit, title: "Documents")
    content = section_content(section)
    first = attach_file!(content, "first.txt", "text/plain", "First\n", "First")
    second = attach_file!(content, "second.txt", "text/plain", "Second\n", "Second")
    content.recording_studio_orderable_append!(first, actor: @user)
    content.recording_studio_orderable_append!(second, actor: @user)
    content.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    body = response.body
    assert_operator body.index("Second"), :<, body.index("First")
    assert_equal [second.id, first.id], RecordingStudioPresskits::DirectFiles.list(content.reload).map(&:id)
    assert_select "[data-presskits-file-id='#{second.id}'] [data-presskits-file-name]", text: "Second"
    assert_select "[data-presskits-file-meta]", text: /TXT/
    assert_select "a[href*='/attachments/']", count: 0
  end

  test "remove trashes the attachment" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit)
    content = section_content(section)
    file = attach_file!(content, "keep.txt")
    sign_in @user
    switch_to_root(@root)
    return_to = recording_studio_presskits.edit_press_kit_section_path(kit, section)

    delete recording_studio_attachable.destroy_attachment_path(
      file,
      redirect_mode: "return_to",
      return_to: return_to
    )
    assert_redirected_to return_to
    follow_redirect!

    assert file.reload.trashed_at
    assert_empty RecordingStudioPresskits::DirectFiles.list(content.reload)
  end

  test "rejects an image a huge file and an eleventh file" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit)
    content = section_content(section)
    image = declared_attachment_blob!(
      content, @user,
      io: StringIO.new("not-an-image"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    image_result = RecordingStudioAttachable::Services::RecordAttachmentUpload.call(
      parent_recording: content,
      signed_blob_id: attachment_signed_id(image),
      actor: @user
    )
    assert image_result.failure?
    assert_includes image_result.error, "is not allowed"

    huge = declared_attachment_blob!(
      content, @user,
      io: StringIO.new("x"),
      filename: "huge.pdf",
      content_type: "application/pdf"
    )
    huge.update!(byte_size: 26.megabytes)
    huge_result = RecordingStudioAttachable::Services::RecordAttachmentUpload.call(
      parent_recording: content,
      signed_blob_id: attachment_signed_id(huge),
      actor: @user
    )
    assert huge_result.failure?
    assert_equal "Blob exceeds maximum file size", huge_result.error

    10.times { |index| attach_file!(content, "note-#{index}.txt") }
    extra = declared_attachment_blob!(
      content, @user,
      io: StringIO.new("nope"),
      filename: "extra.txt",
      content_type: "text/plain"
    )
    extra_result = RecordingStudioAttachable::Services::RecordAttachmentUpload.call(
      parent_recording: content,
      signed_blob_id: attachment_signed_id(extra),
      actor: @user
    )
    assert extra_result.failure?
    assert_equal RecordingStudioPresskits::FileQuota.message, extra_result.error
    assert_equal 10, RecordingStudioPresskits::DirectFiles.list(content.reload).size
  end

  test "a second batch cannot slip past the ten file cap" do
    kit = record_kit("Spring launch")
    content = section_content(add_files_section(kit))
    9.times { |index| attach_file!(content, "note-#{index}.txt") }
    blobs = Array.new(2) do |index|
      declared_attachment_blob!(
        content, @user,
        io: StringIO.new("batch"),
        filename: "batch-#{index}.txt",
        content_type: "text/plain"
      )
    end

    result = RecordingStudioAttachable::Services::RecordAttachmentUploads.call(
      parent_recording: content,
      actor: @user,
      attachments: blobs.map { |blob| { signed_blob_id: attachment_signed_id(blob) } }
    )

    assert result.failure?
    assert_equal RecordingStudioPresskits::FileQuota.message, result.error
    assert_equal 9, RecordingStudioPresskits::DirectFiles.list(content.reload).size
  end

  test "the public kit lists files without a download link" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit, title: "Documents", subtitle: "Take the kit.")
    content = section_content(section)
    file = attach_file!(content, "one-sheet.pdf", "application/pdf", "%PDF-1.1\n%%EOF\n", "One-sheet")
    file.revise_attachment_metadata(actor: @user, description: "The short version.")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "h2", text: "Documents"
    assert_includes response.body, "Take the kit."
    assert_select "[data-presskits-files].flat-pack-list-divided"
    row = css_select("[data-presskits-file-id='#{file.id}']").first
    assert_operator row.to_html.index("data-presskits-file-description"), :<, row.to_html.index("data-presskits-file-meta")
    assert_select "[data-presskits-file-name]", text: "One-sheet"
    assert_select "[data-presskits-file-description]", text: "The short version."
    assert_select "[data-presskits-file-meta]", text: /PDF/
    assert_select "[data-flat-pack--icon-name-value='document-text']"
    assert_select "a[href*='attachments/#{file.id}']", count: 0
  end

  test "the kit zip puts each files section in its own folder" do
    kit = record_kit("Spring launch")
    first = add_files_section(kit, title: "Documents")
    second = add_files_section(kit, title: "Documents")
    attach_file!(section_content(first), "one-sheet.pdf", "application/pdf", "%PDF-1.1\n%%EOF\n", "One-sheet")
    attach_file!(section_content(second), "one-sheet.pdf", "application/pdf", "%PDF-1.1\n%%EOF\n", "One-sheet")
    attach_file!(section_content(second), "bios.txt", "text/plain", "Bios\n", "Bios")
    publish_kit!(kit)

    names = kit.recordable.downloadable_manifest.map(&:filename)
    assert_includes names, "Documents/one-sheet.pdf"
    assert_includes names, "Documents-2/one-sheet.pdf"
    assert_includes names, "Documents-2/bios.txt"
    text = kit.recordable.downloadable_manifest.find { |file| file.filename == "kit.txt" }
    body = text.with_io(&:read)
    assert_includes body, "One-sheet"
    assert_includes body, "one-sheet.pdf"

    payload = nil
    RecordingStudioDownloadable::ZipBuilder.new(kit.recordable.downloadable_manifest).write do |io|
      payload = io.read
    end
    entries = Zip::File.open_buffer(payload).map(&:name)
    assert_includes entries, "Documents/one-sheet.pdf"
    assert_includes entries, "Documents-2/one-sheet.pdf"
    assert_includes entries, "Documents-2/bios.txt"
    assert_includes entries, "kit.txt"
  end

  test "a direct attachment link cannot bypass kit download" do
    kit = record_kit("Spring launch")
    content = section_content(add_files_section(kit))
    file = attach_file!(content, "secret.txt", "text/plain", "secret-bytes", "Secret")
    sign_in @user

    get recording_studio_attachable.download_attachment_path(file, format: :json)
    assert_response :forbidden
    get recording_studio_attachable.attachment_file_path(file, format: :json)
    assert_response :forbidden
    refute_includes response.body, "secret-bytes"

    publish_kit!(kit)
    get recording_studio_attachable.download_attachment_path(file)
    assert_response :success
    assert_equal "secret-bytes", response.body

    hold_kit!(kit)
    sign_out @user
    Current.actor = nil
    get recording_studio_attachable.download_attachment_path(file)
    assert_response :redirect
    refute_includes response.body, "secret-bytes"

    outsider = User.create!(
      email: "outsider-files-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    Current.actor = outsider
    get recording_studio_attachable.download_attachment_path(file, format: :json)
    assert_response :forbidden
    refute_includes response.body, "secret-bytes"
    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden
  end

  test "a view grant cannot download a file when the kit download is granted only" do
    kit = record_kit("Spring launch")
    content = section_content(add_files_section(kit))
    file = attach_file!(content, "secret.txt", "text/plain", "secret-bytes", "Secret")
    publish_kit!(kit)
    RecordingStudioPresskits::KitDownload.set_audience!(recording: kit, audience: :granted, actor: @user)
    viewer = User.create!(
      email: "view-only-files-#{SecureRandom.hex(4)}@example.com",
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
    get recording_studio_attachable.download_attachment_path(file, format: :json)
    assert_response :forbidden
    get recording_studio_downloadable.recording_package_path(kit)
    assert_response :forbidden
  end

  test "trashing a files section hides its files and restore brings them back" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit, title: "Documents")
    content = section_content(section)
    file = attach_file!(content, "bios.txt", "text/plain", "Bios\n", "Bios")
    publish_kit!(kit)

    section.recording_studio_trashable_trash!(actor: @user)
    assert section.reload.trashed_at
    assert file.reload.trashed_at

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-file-name]", text: "Bios", count: 0

    section.recording_studio_trashable_restore!(actor: @user)
    refute section.reload.trashed_at
    refute file.reload.trashed_at
    assert_equal [file.id], RecordingStudioPresskits::DirectFiles.list(content.reload).map(&:id)
  end

  test "a duplicated kit gets independent file copies" do
    kit = record_kit("Spring launch")
    section = add_files_section(kit, title: "Documents")
    content = section_content(section)
    file = attach_file!(content, "shared.txt", "text/plain", "Shared\n", "Shared")
    file.revise_attachment_metadata(actor: @user, description: "Original")

    copy = kit.duplicate_in_place!(actor: @user)
    copy_section = RecordingStudioPresskits::KitQuery.sections_for(copy).find do |item|
      section_content(item)&.recordable.is_a?(RecordingStudioPresskits::Files)
    end
    copy_content = section_content(copy_section)
    copy_file = RecordingStudioPresskits::DirectFiles.list(copy_content).first

    refute_equal file.id, copy_file.id
    refute_equal file.recordable.file.blob.id, copy_file.recordable.file.blob.id
    assert_equal "Original", copy_file.recordable.description

    copy_file.revise_attachment_metadata(actor: @user, description: "Changed")
    assert_equal "Original", file.reload.recordable.description
    copy_file.remove_attachment(actor: @user)
    assert file.reload.recordable.file.attached?
    assert_nil file.trashed_at
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_files_section(kit, title: "Files", subtitle: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Files",
      actor: @user,
      title: title,
      subtitle: subtitle
    )
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def attach_file!(parent, filename, content_type = "text/plain", body = "hello", name = nil)
    blob = issued_attachment_blob!(
      parent, @user,
      io: StringIO.new(body),
      filename: filename,
      content_type: content_type
    )
    parent.record_attachment_upload(
      signed_blob_id: attachment_signed_id(blob),
      actor: @user,
      name: name || File.basename(filename, ".*")
    )
  end

  def uploaded(filename, content_type, body)
    tempfile = Tempfile.new(filename)
    tempfile.write(body)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, content_type, true, original_filename: filename)
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-files-#{SecureRandom.hex(4)}", status: "published" }
    )
    raise result.error if result.failure?

    kit.reload
  end

  def hold_kit!(kit)
    RecordingStudioPresskits::KitSettings.save_fallback!(recording: kit, fallback: :preview, actor: @user)
    kit.embargo_set!(
      {
        enabled: true,
        lifts_at: 1.day.from_now.change(sec: 0),
        time_zone: "UTC",
        early_access: true
      },
      actor: @user
    )
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
