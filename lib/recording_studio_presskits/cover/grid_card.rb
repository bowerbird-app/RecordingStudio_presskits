# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    module GridCard
      # Tailwind scans these literals: "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
      def grid_card_classes
        "h-full w-full shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
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
