# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

require_relative "support/presskits_api_mirror"
require_relative "support/attachable_blobs"

class FilePayloadTest < ActiveSupport::TestCase
  include PresskitsApiMirror
  include AttachableBlobs

  test "section payload lists active files in order and leaves out urls" do
    built = section_with_files
    section = built.fetch(:section)
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    files = payload.fetch(:files)

    assert_equal "Documents", payload[:title]
    assert_equal "For the desk", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::Files", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    names = files.map { |entry| entry[:name] }
    assert_equal %w[One-sheet Bios], names
    assert_equal %i[id name description original_filename content_type byte_size position], files.first.keys
    assert_equal "one-sheet.pdf", files.first[:original_filename]
    assert_equal "application/pdf", files.first[:content_type]
    assert_equal "Short description of the spring film.", files.first[:description]
    assert_operator files.first[:byte_size], :>, 0
    assert_not_includes files.first.keys, :url
    assert_not_includes files.map { |entry| entry[:name] }, "Gone"
  end

  test "files section api serializer returns the same files list" do
    built = section_with_files
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudioPresskits::Files").fetch(:serializer)

    assert_equal payload.fetch(:files), serializer.call(content.recordable, recording: content).fetch(:files)
  end

  test "a text section payload stays at four keys" do
    built = section_with_files
    text = built.fetch(:text)

    assert_equal %i[title subtitle content_type content_id],
                 RecordingStudioPresskits::Api::SectionPayload.for(text.recordable, text).keys
  end

  private

  def section_with_files
    root, kit = kit_tree
    user = owner_for(root)
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: user,
      title: "Notes"
    )
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Files",
      actor: user,
      title: "Documents",
      subtitle: "For the desk"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    first = attach_file!(content, user, "one-sheet.pdf", "One-sheet")
    first.revise_attachment_metadata(actor: user, description: "Short description of the spring film.")
    content.recording_studio_orderable_append!(first, actor: user)
    second = attach_file!(content, user, "bios.txt", "Bios")
    content.recording_studio_orderable_append!(second, actor: user)
    gone = attach_file!(content, user, "gone.txt", "Gone")
    gone.recording_studio_trashable_trash!(actor: user)

    { text: text, section: section, content: content }
  end

  def attach_file!(parent, actor, filename, name)
    pdf = filename.end_with?(".pdf")
    blob = issued_attachment_blob!(
      parent, actor,
      io: StringIO.new(pdf ? "%PDF-1.1\n%%EOF\n" : "#{name}\n"),
      filename: filename,
      content_type: pdf ? "application/pdf" : "text/plain"
    )
    parent.record_attachment_upload(signed_blob_id: attachment_signed_id(blob), actor: actor, name: name)
  end

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "File payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "file-payload-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = user
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root_recording, actor: user)
    raise result.error if result.failure?

    user
  ensure
    Current.actor = previous
  end

  def fake_api_registry
    Class.new do
      def types
        @types ||= {}
      end

      def register_recordable_type_api(type_name, **registration)
        types[type_name] = registration
      end

      def capability_action(name)
        capability_actions[name.to_sym]
      end

      def register_capability_action(name, **registration)
        capability_actions[name.to_sym] = registration
      end

      def capability_actions
        @capability_actions ||= {}
      end
    end.new
  end
end
