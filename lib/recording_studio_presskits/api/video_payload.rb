# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class VideoPayload
      KEYS = %i[title url description provider canonical_url content_type duration_seconds thumbnail_url].freeze

      def self.for(recordable, context: nil)
        return KEYS.index_with { nil } if Exposure.withhold?(context, recording_for(recordable, context))

        KEYS.index_with { |name| value_for(recordable, name) }
      end

      def self.value_for(recordable, name)
        return recordable.poster_url if name == :thumbnail_url && recordable.respond_to?(:poster_url)

        recordable.public_send(name)
      end
      private_class_method :value_for

      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        VideoSection.active_videos(recording).map { |child| VideoPayload.for(child.recordable) }
      end

      def self.recording_for(recordable, context)
        return context.recording if context.respond_to?(:recording) && context.recording.present?
        return unless defined?(RecordingStudio::Recording)

        RecordingStudio::Recording.find_by(recordable: recordable)
      end
      private_class_method :recording_for
    end
  end
end
