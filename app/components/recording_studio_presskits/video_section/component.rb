# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def videos
        VideoSection.active_videos(@recording)
      end

      def player_for(video_recording)
        helpers.recording_studio_video_player(video_recording)
      end
    end
  end
end
