# frozen_string_literal: true

require "recording_studio_presskits/api/quote_payload"
require "recording_studio_presskits/api/section_payload"

module RecordingStudioPresskits
  module Api
    class << self
      def register!
        return unless defined?(::RecordingStudioApi)

        register_kit_section
        register_text
        register_quote
        register_quote_section
      end

      private

      def register_kit_section
        register_type(
          "RecordingStudioPresskits::KitSection",
          operations: %i[index show update],
          serializer: kit_section_serializer,
          output_keys: %i[title subtitle content_type content_id],
          writable_attributes: %i[title subtitle]
        )
      end

      def kit_section_serializer
        lambda { |recordable, recording: nil, **|
          SectionPayload.for(recordable, recording)
        }
      end

      def register_text
        register_type(
          "RecordingStudioPresskits::Text",
          operations: %i[show update],
          serializer: ->(recordable, **) { { body: recordable.body } },
          output_keys: %i[body],
          writable_attributes: %i[body]
        )
      end

      def register_quote
        ::RecordingStudioApi.register_recordable_type_api(
          "RecordingStudioPresskits::Quote",
          **quote_registration
        )
      end

      def quote_registration
        {
          operations: %i[index show create update destroy],
          serializer: quote_serializer,
          output_keys: quote_keys,
          writable_attributes: quote_keys
        }
      end

      def quote_keys
        %i[body name role organisation]
      end

      def quote_serializer
        ->(recordable, **) { QuotePayload.for(recordable) }
      end

      def register_quote_section
        register_type("RecordingStudioPresskits::QuoteSection", **empty_section_options)
      end

      def register_type(type_name, **)
        ::RecordingStudioApi.register_recordable_type_api(type_name, **)
      end

      def empty_section_options
        {
          operations: %i[index show],
          serializer: empty_serializer,
          output_keys: []
        }
      end

      def empty_serializer
        ->(_recordable) { {} }
      end
    end
  end
end
