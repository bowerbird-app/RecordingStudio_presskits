# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    # Default card actions for the gem's own screens. Cover::Component only
    # renders whatever the caller passes through `with_action`.
    class DefaultActionsComponent < ViewComponent::Base
      BUTTON_WIDTH = "w-full @min-[640px]:w-auto"

      def initialize(cover:, recording:, context:, href: nil, preview: false)
        super()
        @cover = cover
        @recording = recording
        @context = context.to_sym
        @href = href.presence
        @preview = preview
      end

      def grid?
        @context == :grid
      end

      def view_button
        return if @href.blank?

        button(
          text: I18n.t("recording_studio_presskits.cover.view"),
          icon: "arrow-right",
          href: @href,
          extra_class: "rounded-full [&>svg]:order-last",
          data: { cover_view: true }
        )
      end

      def download_button
        return if grid? || @preview
        return unless downloadable?

        button(
          text: I18n.t("recording_studio_presskits.download.button"),
          icon: "arrow-down-tray",
          href: links.download_href,
          data: { cover_download: true }
        )
      end

      def contact_button
        return if grid?
        return if links.contact_href.blank?

        button(
          text: I18n.t("recording_studio_presskits.cover.contact"),
          style: :secondary,
          href: links.contact_href,
          data: { cover_contact: true }
        )
      end

      private

      def downloadable?
        return false if @recording.blank?

        KitDownload.allowed?(@recording, actor: links.actor) && links.download_href.present?
      end

      def links
        @links ||= ActionLinks.new(recording: @recording, helpers: helpers)
      end

      def button(text:, href:, data:, icon: nil, style: :primary, extra_class: nil) # rubocop:disable Metrics/ParameterLists
        FlatPack::Button::Component.new(
          text: text,
          icon: icon,
          style: style,
          size: :lg,
          href: href,
          class: [BUTTON_WIDTH, extra_class].compact.join(" "),
          data: data
        )
      end
    end
  end
end
