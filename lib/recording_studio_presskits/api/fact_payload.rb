# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class FactPayload
      def self.for(recordable, context: nil)
        if Exposure.withhold?(context, recording_for(recordable, context))
          return { label: nil, value: nil, unit: nil, description: nil, source_url: nil, as_of_date: nil }
        end

        {
          label: recordable.label,
          value: recordable.value,
          unit: blank_to_nil(recordable.unit),
          description: blank_to_nil(recordable.description),
          source_url: blank_to_nil(recordable.source_url),
          as_of_date: recordable.as_of_date
        }
      end

      def self.for_recording(recording, context: nil)
        if Exposure.withhold?(context, recording)
          return { display: { style: nil, columns: nil }, facts: [] }
        end

        {
          display: display_for(recording&.recordable),
          facts: FactsSection.active_facts(recording).map { |child| FactPayload.for(child.recordable) }
        }
      end

      def self.recording_for(recordable, context)
        return context.recording if context.respond_to?(:recording) && context.recording.present?
        return unless defined?(RecordingStudio::Recording)

        RecordingStudio::Recording.find_by(recordable: recordable)
      end
      private_class_method :recording_for

      def self.display_for(recordable)
        {
          style: recordable&.display_style.presence || FactsSection::DEFAULT_DISPLAY_STYLE,
          columns: recordable&.columns.presence || FactsSection::DEFAULT_COLUMNS
        }
      end
      private_class_method :display_for

      def self.blank_to_nil(value)
        value.to_s.strip.presence
      end
      private_class_method :blank_to_nil
    end
  end
end
