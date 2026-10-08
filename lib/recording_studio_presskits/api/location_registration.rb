# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module LocationRegistration
      private

      def register_location
        register_type(
          LocationContent::TYPE_NAME,
          operations: %i[show update],
          serializer: ->(recordable, **) { LocationPayload.for(recordable) },
          output_keys: LocationPayload::KEYS,
          writable_attributes: LocationPayload::KEYS
        )
      end
    end
  end
end
