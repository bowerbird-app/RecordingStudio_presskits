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
        register_type("RecordingStudioPresskits::ListSection", **empty_section_options)
      end
    end
  end
end
