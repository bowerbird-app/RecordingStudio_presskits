# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class StatPayload
      def self.for(recordable, context: nil)
        return withheld_stat if Exposure.withhold?(context, recording_for(recordable, context))

        {
          label: recordable.label,
          value: recordable.value,
          unit: blank_to_nil(recordable.unit),
          description: blank_to_nil(recordable.description)
        }
      end

      def self.for_recording(recording, context: nil)
        return withheld_section if Exposure.withhold?(context, recording)

        {
          stats: StatsSection.active_stats(recording).map { |child| StatPayload.for(child.recordable) }
        }
      end

      def self.withheld_stat
        { label: nil, value: nil, unit: nil, description: nil }
      end
      private_class_method :withheld_stat

      def self.withheld_section
        { stats: [] }
      end
      private_class_method :withheld_section

      def self.recording_for(recordable, context)
        return context.recording if context.respond_to?(:recording) && context.recording.present?
        return unless defined?(RecordingStudio::Recording)

        RecordingStudio::Recording.find_by(recordable: recordable)
      end
      private_class_method :recording_for

      def self.blank_to_nil(value)
        value.to_s.strip.presence
      end
      private_class_method :blank_to_nil
    end
  end
end
