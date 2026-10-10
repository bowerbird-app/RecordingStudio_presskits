# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module LocationRegistration
      def register_location_section
        register_type(
          "RecordingStudioPresskits::LocationSection",
          operations: %i[index show],
          serializer: location_section_serializer,
          output_keys: %i[locations]
        )
      end

      private

      def location_section_serializer
        lambda { |_recordable, recording: nil, **|
          { locations: LocationPayload.for_recording(recording) }
        }
      end
    end
  end
end
