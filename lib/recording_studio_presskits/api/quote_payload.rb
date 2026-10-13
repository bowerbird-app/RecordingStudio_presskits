# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class QuotePayload
      def self.for(recordable, context: nil)
        return { body: nil, name: nil } if Exposure.withhold?(context, recording_for(recordable, context))

        { body: recordable.body, name: recordable.name }.tap do |payload|
          assign_present(payload, :role, recordable.role)
          assign_present(payload, :organisation, recordable.organisation)
        end
      end

      def self.recording_for(recordable, context)
        return context.recording if context.respond_to?(:recording) && context.recording.present?
        return unless defined?(RecordingStudio::Recording)

        RecordingStudio::Recording.find_by(recordable: recordable)
      end
      private_class_method :recording_for

      def self.assign_present(payload, key, value)
        stripped = value.to_s.strip
        payload[key] = stripped if stripped.present?
      end
      private_class_method :assign_present
    end
  end
end
