# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class PressKitPayload
      def self.for(recordable, context: nil)
        payload = {
          title: recordable.title,
          subtitle: recordable.subtitle,
          description: recordable.description,
          cover_style: recordable.resolved_cover_style,
          cover_color: recordable.resolved_cover_color,
          cover_text_color: recordable.resolved_cover_text_color
        }
        return payload unless Exposure.withhold?(context, recording_for(recordable, context))

        payload.merge(description: nil)
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
