# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        videos.any?
      end

      def videos
        @videos ||= VideoSection.active_videos(@recording).to_a
      end
    end
  end
end
