# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class FactPayload
      def self.for(recordable)
        {
          label: recordable.label,
          value: recordable.value,
          unit: blank_to_nil(recordable.unit),
          description: blank_to_nil(recordable.description),
          source_url: blank_to_nil(recordable.source_url),
          as_of_date: recordable.as_of_date
        }
      end

      def self.for_recording(recording)
        {
          display: display_for(recording&.recordable),
          facts: FactsSection.active_facts(recording).map { |child| FactPayload.for(child.recordable) }
        }
      end

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
