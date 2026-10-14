# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastSection
    class CardComponent < ViewComponent::Base
      # About 1.2 cards on a phone, about 3 from md. Tailwind scans:
      # "w-[83.333%]" "shrink-0" "snap-start" "md:w-[calc((100%-2rem)/3)]"
      # "flex" "min-w-0" "flex-col" "gap-3"
      CARD_CLASSES = "flex w-[83.333%] shrink-0 snap-start flex-col gap-3 md:w-[calc((100%-2rem)/3)]"

      def initialize(podcast_recording:)
        super()
        @podcast_recording = podcast_recording
      end

      def card_classes
        CARD_CLASSES
      end

      def title
        podcast.episode_title
      end

      def show_name
        podcast.show_name.to_s.strip.presence
      end

      def meta
        podcast.meta_line
      end

      def url
        podcast.url.to_s
      end

      def image_url
        PodcastArtwork.image_url(@podcast_recording, helpers: helpers)
      end

      def embed_url
        podcast.embed.embed_url
      end

      def brand_color
        KitBranding.for(kit_recording).brand_color
      end

      def play_label
        I18n.t("recording_studio_presskits.podcasts.play", title: title)
      end

      def listen_label
        service = podcast.embed.service
        return if service.blank?

        I18n.t("recording_studio_presskits.podcasts.listen", service: service)
      end

      def copy_label
        I18n.t("recording_studio_presskits.podcasts.copy_link")
      end

      def copied_label
        I18n.t("recording_studio_presskits.podcasts.copied")
      end

      def copy_failed_label
        I18n.t("recording_studio_presskits.podcasts.copy_failed")
      end

      def dom_id
        "presskits-podcast-#{@podcast_recording.id}"
      end

      private

      def podcast
        @podcast_recording.recordable
      end

      def kit_recording
        @podcast_recording.parent_recording&.parent_recording&.parent_recording
      end
    end
  end
end
