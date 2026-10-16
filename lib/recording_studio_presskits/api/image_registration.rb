# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ImageRegistration
      def register_images!
        register_type(
          "RecordingStudioPresskits::Images",
          operations: %i[index show],
          serializer: ImagePayload.method(:for_section),
          output_keys: %i[images],
          capability_actions: %i[update_image reorder_images remove_image]
        )
      end
    end
  end
end
