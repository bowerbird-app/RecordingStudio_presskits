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
          data: { cover_view: true }
        )
      end

      def download_button
        return if grid? || @preview
        return unless downloadable?

        helpers.recording_studio_downloadable_button(@recording, **download_options) do
          helpers.render(satisfied_download_button)
        end
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
        return false unless helpers.respond_to?(:recording_studio_downloadable_button)

        KitDownload.allowed?(@recording, actor: links.actor)
      end

      def download_label
        I18n.t("recording_studio_presskits.download.button")
      end

      def download_options
        {
          style: :primary,
          size: :lg,
          ready_text: download_label,
          generate_text: download_label,
          preparing_text: I18n.t("recording_studio_presskits.download.preparing"),
          retry_text: I18n.t("recording_studio_presskits.download.retry")
        }
      end

      def satisfied_download_button
        button(
          text: download_label,
          icon: "arrow-down-tray",
          type: "button",
          data: { cover_download: true }
        )
      end

      def links
        @links ||= ActionLinks.new(recording: @recording, helpers: helpers)
      end

      def button(text:, data:, icon: nil, style: :primary, **extras)
        options = { text: text, icon: icon, style: style, size: :lg, class: BUTTON_WIDTH, data: data }
        options[:href] = extras[:href] if extras[:href].present?
        options[:type] = extras[:type] if extras[:type].present?
        FlatPack::Button::Component.new(**options)
      end
    end
  end
end
