# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module LocationRegistration
      include FileRegistration

      def register_location_section
        register_location_type
        register_files!
      end

      private

      def register_location_type
        register_type(
          "RecordingStudioPresskits::LocationSection",
          operations: %i[index show],
          serializer: method(:location_section_serializer),
          output_keys: %i[locations],
          capability_actions: %i[set_location update_location clear_location reorder_locations]
        )
      end

      def location_section_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        { locations: LocationPayload.for_recording(source, context: context) }
      end
    end
  end
end
