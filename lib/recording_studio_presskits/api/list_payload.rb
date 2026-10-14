# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class ListPayload
      def self.for(recordable, context: nil)
        return withheld_item if Exposure.withhold?(context, recording_for(recordable, context))

        {
          icon: blank_to_nil(recordable.icon),
          key: recordable.key,
          value: recordable.value
        }
      end

      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        ListSection.active_items(recording).map { |child| ListPayload.for(child.recordable) }
      end

      def self.withheld_item
        { icon: nil, key: nil, value: nil }
      end
      private_class_method :withheld_item

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
