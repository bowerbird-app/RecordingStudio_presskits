# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class LocationPayload
      def self.for(recordable, context: nil)
        return {} if Exposure.withhold?(context, recording_for(recordable, context))

        recordable.api_payload
      end

      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        LocationSection.active_locations(recording).map { |child| LocationPayload.for(child.recordable) }
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
