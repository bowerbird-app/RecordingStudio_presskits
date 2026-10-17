# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module MenuRegistration
      def register_menu!
        register_type(
          "RecordingStudioPresskits::MenuSection",
          operations: %i[index show update],
          serializer: MenuPayload.method(:for),
          output_keys: MenuPayload::KEYS,
          writable_attributes: MenuPayload::KEYS
        )
      end
    end
  end
end
