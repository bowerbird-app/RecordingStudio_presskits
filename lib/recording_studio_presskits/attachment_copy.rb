# frozen_string_literal: true

require "stringio"

module RecordingStudioPresskits
  class AttachmentCopy
    def self.call(recordable)
      copy = recordable.dup
      attach_independent_file(recordable, copy)
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
  end
end
