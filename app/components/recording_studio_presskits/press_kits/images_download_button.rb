# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    # Heading action for an images section. Downloadable renders the gate
    # component until a purpose is chosen, then this button inside the poller.
    class ImagesDownloadButton
      def self.for(content, helpers:)
        new(content, helpers).render
      end

      def initialize(content, helpers)
        @content = content
        @helpers = helpers
      end

      def render
        return unless images?
        return if DirectImages.list(@content).empty?
        return unless @helpers.respond_to?(:recording_studio_downloadable_button)

        @helpers.recording_studio_downloadable_button(@content, **options) { @helpers.render(control) }
      end

      private

      def images?
        @content&.recordable.is_a?(Images)
      end

      def label
        I18n.t("recording_studio_presskits.images.download_all")
      end

      def options
        {
          style: :default,
          size: :md,
          ready_text: label,
          generate_text: label,
          preparing_text: I18n.t("recording_studio_presskits.download.preparing"),
          retry_text: I18n.t("recording_studio_presskits.download.retry")
        }
      end

      def control
        FlatPack::Button::Component.new(
          text: label,
          style: :default,
          size: :md,
          icon: "arrow-down-tray",
          type: "button",
          data: { images_download: true }
        )
      end
    end
  end
end
