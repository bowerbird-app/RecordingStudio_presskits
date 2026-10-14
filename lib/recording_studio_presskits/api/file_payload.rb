# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class FilePayload
      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        DirectFiles.list(recording).map { |child| entry(child) }
      end

      def self.entry(recording)
        attachment = recording.recordable
        {
          id: recording.id,
          name: attachment.name,
          description: attachment.description,
          original_filename: attachment.original_filename,
          content_type: attachment.content_type,
          byte_size: attachment.byte_size,
          position: recording.try(:recording_studio_orderable_position)
        }
      end
    end
  end
end
