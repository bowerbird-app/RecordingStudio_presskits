# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ListRegistration
      def register_lists!
        register_list_item
        register_list_section
      end

      private

      def register_list_item
        register_type(
          "RecordingStudioPresskits::ListItem",
          operations: %i[index show create update destroy],
          serializer: ->(recordable, context: nil, **) { ListPayload.for(recordable, context: context) },
          output_keys: list_item_keys,
          writable_attributes: list_item_keys
        )
      end

      def list_item_keys
        %i[icon key value]
      end

      def register_list_section
        register_type(
          "RecordingStudioPresskits::ListSection",
          operations: %i[index show],
          serializer: list_section_serializer,
          output_keys: %i[items]
        )
      end

      def list_section_serializer
        lambda { |_recordable, recording: nil, context: nil, **|
          source = Exposure.named_recording(recording: recording, context: context)
          { items: ListPayload.for_recording(source, context: context) }
        }
      end
    end
  end
end
