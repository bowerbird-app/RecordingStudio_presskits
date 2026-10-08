# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module FactRegistration
      def register_facts!
        register_fact
        register_facts_section
      end

      private

      def register_fact
        register_type(
          "RecordingStudioPresskits::Fact",
          operations: %i[index show create update destroy],
          serializer: ->(recordable, **) { FactPayload.for(recordable) },
          output_keys: fact_keys,
          writable_attributes: fact_keys
        )
      end

      def fact_keys
        %i[label value unit description source_url as_of_date]
      end

      def register_facts_section
        register_type(
          "RecordingStudioPresskits::FactsSection",
          operations: %i[index show update],
          serializer: facts_section_serializer,
          output_keys: %i[display facts],
          writable_attributes: %i[display_style columns]
        )
      end

      def facts_section_serializer
        lambda { |recordable, recording: nil, **|
          FactPayload.for_recording(recording || RecordingStudio::Recording.find_by(recordable: recordable))
        }
      end
    end
  end
end
