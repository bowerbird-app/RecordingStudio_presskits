# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module FileRegistration
      def register_files!
        register_type(
          "RecordingStudioPresskits::Files",
          operations: %i[index show],
          serializer: method(:files_serializer),
          output_keys: %i[files],
          capability_actions: %i[update_file reorder_files remove_file]
        )
      end

      private

      def files_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        { files: FilePayload.for_recording(source, context: context) }
      end
    end
  end
end
