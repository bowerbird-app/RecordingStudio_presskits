# frozen_string_literal: true

require "stringio"

module RecordingStudioPresskits
  class AttachmentCopy
    def self.call(recordable)
      copy = recordable.dup
      attach_independent_file(recordable, copy)
      copy.validation_options = validation_options_for(recordable)
      copy
    end

    def self.attach_independent_file(recordable, copy)
      return unless recordable.respond_to?(:file) && recordable.file.attached?

      blob = recordable.file.blob
      io = StringIO.new(recordable.file.download)
      io.binmode
      copy.file.attach(
        io: io,
        filename: blob.filename.to_s,
        content_type: blob.content_type
      )
    end

    # A copied file is validated again. The allowlist lives on the parent, not
    # on the attachment row, so a text file would fail the global image/pdf list.
    def self.validation_options_for(recordable)
      return {} unless defined?(RecordingStudio::Recording && RecordingStudio)

      recording = RecordingStudio::Recording.find_by(recordable: recordable)
      type = recording&.parent_recording&.recordable_type
      return {} if type.blank?

      options = RecordingStudio.capability_options(:attachable, for_type: type)
      options.to_h.slice(:allowed_content_types, :enabled_attachment_kinds)
    rescue StandardError
      {}
    end
    private_class_method :validation_options_for
  end
end
