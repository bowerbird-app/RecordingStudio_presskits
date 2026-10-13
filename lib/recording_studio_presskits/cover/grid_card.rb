# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    module GridCard
      # Tailwind scans these literals: "@container" "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
      def grid_card_classes
        "@container h-full w-full shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
      end

      # Wide layout keys off the card's own width. Tailwind scans these literals:
      # "@min-[640px]:min-h-[50cqw]" "@min-[640px]:flex-row"
      def grid_card_row_classes
        "flex h-full w-full flex-1 flex-col @min-[640px]:min-h-[50cqw] @min-[640px]:flex-row"
      end

      # Tailwind scans these literals: "aspect-[430/368]" "rounded-t-[var(--radius-lg)]"
      # "@min-[640px]:aspect-auto" "@min-[640px]:w-1/2" "@min-[640px]:shrink-0"
      # "@min-[640px]:min-h-[50cqw]" "@min-[640px]:rounded-tr-none"
      # "@min-[640px]:rounded-bl-[var(--radius-lg)]" "@min-[640px]:min-w-0"
      def grid_card_frame_classes
        [
          "relative aspect-[430/368] w-full overflow-hidden rounded-t-[var(--radius-lg)]",
          "@min-[640px]:aspect-auto @min-[640px]:w-1/2 @min-[640px]:shrink-0",
          "@min-[640px]:min-h-[50cqw] @min-[640px]:self-stretch",
          "@min-[640px]:rounded-tr-none @min-[640px]:rounded-bl-[var(--radius-lg)]"
        ].join(" ")
      end

      def grid_card_body_classes
        "flex flex-1 flex-col px-8 pt-7 @min-[640px]:min-w-0"
      end

      def grid_card_data
        { cover_card: true, cover_color: cover_color, cover_style: cover_style }
      end

      def view_button_theme
        {
          primary: cover_color,
          primary_hover: cover_color,
          primary_text: Contrast.text_on(cover_color)
        }
      end

      def view_label
        I18n.t("recording_studio_presskits.cover.view")
      end

      def show_add_to_list?
        return false unless card?
        return false unless lists_installed?
        return false if current_actor.blank?
        return false if @recording.blank?
        return false unless helpers.respond_to?(:recording_studio_add_to_list)

        true
      end

      def list_parent
        return unless @recording.respond_to?(:root_recording_or_self)

        @recording.root_recording_or_self
      end

      def show_brand_row?
        company_name.present? || show_add_to_list?
      end

      private

      def lists_installed?
        defined?(RecordingStudioLists::AddToListHelper)
      end

      def current_actor
        return unless defined?(Current)
        return unless Current.respond_to?(:actor)

        Current.actor
      end
    end
  end
end
