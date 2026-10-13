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

      # pt-16 on the wide copy, on top of the body's pt-7, so the company name
      # starts about 6rem from the card top. The editor Edit control lives
      # outside this padding. Tailwind scans this literal: "@min-[640px]:pt-16"
      def grid_card_copy_classes
        "flex items-start gap-3 @min-[640px]:pt-16"
      end

      def title_tag
        @title_tag || :h2
      end

      def inline_edit?
        card? && inline_path.present?
      end

      attr_reader :inline_path

      def grid_card_data
        { cover_card: true, brand_color: brand_color, brand_text_color: brand_text_color, presskits_brand: "true" }
      end

      def view_button_theme
        {
          primary: brand_color,
          primary_text: brand_text_color
        }
      end

      # Hover, pressed fill, and the focus ring. Flatpack's theme hash only
      # accepts a plain colour, and a same-colour hover leaves the pressed
      # states on the theme root. These aliases sit beside --color-primary.
      def button_state_style
        BrandStyle.button_state_attribute
      end

      def view_label
        I18n.t("recording_studio_presskits.cover.view")
      end

      def show_add_to_list?
        return false unless card?
        return false unless @add_to_list
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

      def assign_inline_heading(heading, inline_path)
        @title_tag = %i[h1 h2].include?(heading&.to_sym) ? heading.to_sym : :h2
        @inline_path = inline_path.presence
      end

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
