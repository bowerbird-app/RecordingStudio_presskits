# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastSection
    class Component < ViewComponent::Base
      # Tailwind scans: "flex" "items-center" "gap-2" "min-w-0" "flex-1"
      # "snap-x" "snap-mandatory" "gap-4" "overflow-x-auto" "scroll-smooth"
      SCROLLER_CLASSES = "flex min-w-0 flex-1 snap-x snap-mandatory gap-4 overflow-x-auto scroll-smooth"

      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        podcasts.any?
      end

      def podcasts
        @podcasts ||= PodcastSection.active_podcasts(@recording).to_a
      end

      def scroller_classes
        SCROLLER_CLASSES
      end

      def previous_label
        I18n.t("recording_studio_presskits.podcasts.previous")
      end

      def next_label
        I18n.t("recording_studio_presskits.podcasts.next")
      end
    end
  end
end
