# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoSection
    class CardComponent < ViewComponent::Base
      def initialize(video_recording:, featured: false)
        super()
        @video_recording = video_recording
        @featured = featured
      end

      def featured?
        @featured
      end

      def title
        video.title.presence || "Video"
      end

      def meta
        [video.provider_name, video.duration_label].compact.join(" · ").presence
      end

      def duration_label
        video.duration_label
      end

      def poster_url
        video.poster_url
      end

      def watch_url
        video.watch_url
      end

      def play_label
        I18n.t("recording_studio_presskits.videos.play", title: title)
      end

      def copy_label
        I18n.t("recording_studio_presskits.videos.copy_link")
      end

      def player
        helpers.recording_studio_video_player(@video_recording)
      end

      def title_class
        size = featured? ? "text-base" : "text-sm"
        "#{size} font-medium break-words text-(--surface-content-color)"
      end

      def dom_id
        "presskits-video-#{@video_recording.id}"
      end

      private

      def video
        @video_recording.recordable
      end
    end
  end
end
