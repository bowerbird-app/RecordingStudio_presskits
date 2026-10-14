# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module FileRegistration
      def register_files!
        register_type(
          "RecordingStudioPresskits::Files",
          operations: %i[index show],
          serializer: files_serializer,
          output_keys: %i[files]
        )
      end

      private

      def files_serializer
        lambda { |_recordable, recording: nil, context: nil, **|
          source = Exposure.named_recording(recording: recording, context: context)
          { files: FilePayload.for_recording(source, context: context) }
        }
      end
    end
  end
end
