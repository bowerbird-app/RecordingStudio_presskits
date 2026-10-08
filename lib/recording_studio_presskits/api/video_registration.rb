# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module VideoRegistration
      private

      def register_video_section
        register_type(
          "RecordingStudioPresskits::VideoSection",
          operations: %i[index show],
          serializer: lambda { |_recordable, recording: nil, **|
            { videos: VideoPayload.for_recording(recording) }
          },
          output_keys: %i[videos]
        )
      end
    end
  end
end
