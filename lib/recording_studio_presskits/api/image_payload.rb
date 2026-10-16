# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class ImagePayload
      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        DirectImages.list(recording).map { |child| entry(child) }
      end

      def self.for_section(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        { images: for_recording(source, context: context) }
      end

      def self.entry(recording)
        attachment = recording.recordable
        {
          id: recording.id,
          caption: attachment.caption,
          credit: attachment.credit,
          alt_text: attachment.alt_text,
          content_type: attachment.content_type,
          byte_size: attachment.byte_size,
          position: recording.try(:recording_studio_orderable_position)
        }
      end
    end
  end
end
