# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class Component < ViewComponent::Base
      # Public and owner-preview body. Same muted token as other section body copy
      # (video description, cover description). Not the editor's .ProseMirror colour.
      # Tailwind scans these literals:
      # "max-w-[65ch]" "text-base" "leading-7" "text-[var(--surface-muted-content-color)]"
      # "[&_p+p]:mt-5" "[&_ul]:mt-5" "[&_ol]:mt-5" "[&_ul]:list-disc" "[&_ul]:ps-5"
      # "[&_ol]:list-decimal" "[&_ol]:ps-5" "[&_li]:mt-1" "[&_strong]:font-bold"
      # "[&_a]:underline" "[&_h2]:mt-0" "[&_h2]:mb-3" "[&_h2]:text-2xl" "[&_h2]:font-bold"
      # "[&_h2]:leading-tight" "[&_h2]:text-[var(--surface-content-color)]"
      # "[&_h3]:mt-4" "[&_h3]:mb-2" "[&_h3]:text-xl" "[&_h3]:font-bold"
      # "[&_h3]:text-[var(--surface-content-color)]"
      BODY_CLASSES = [
        "max-w-[65ch] text-base leading-7 text-[var(--surface-muted-content-color)]",
        "[&_p+p]:mt-5 [&_ul]:mt-5 [&_ol]:mt-5 [&_ul]:list-disc [&_ul]:ps-5",
        "[&_ol]:list-decimal [&_ol]:ps-5 [&_li]:mt-1 [&_strong]:font-bold [&_a]:underline",
        "[&_h2]:mt-0 [&_h2]:mb-3 [&_h2]:text-2xl [&_h2]:font-bold [&_h2]:leading-tight",
        "[&_h2]:text-[var(--surface-content-color)]",
        "[&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:text-xl [&_h3]:font-bold",
        "[&_h3]:text-[var(--surface-content-color)]"
      ].join(" ").freeze

      # Eight lines at leading-7 (1.75rem). Tailwind scans: "max-h-[14rem]" "overflow-hidden"
      COLLAPSED_CLASSES = "max-h-[14rem] overflow-hidden"

      # Fade into the card, so it follows the theme surface. Tailwind scans:
      # "pointer-events-none" "absolute" "inset-x-0" "bottom-0" "h-16"
      # "bg-gradient-to-t" "from-[var(--card-background-color)]" "to-transparent"
      FADE_CLASSES = [
        "pointer-events-none absolute inset-x-0 bottom-0 h-16",
        "bg-gradient-to-t from-[var(--card-background-color)] to-transparent"
      ].join(" ").freeze

      # FlatPack::Collapse is a titled disclosure. It hides the whole region.
      # Long public copy keeps about eight lines and a fade, so the toggle is local.
      #
      # The designed three-paragraph blurb is a little past eight lines at 65ch
      # and stays open. Longer copy clamps.
      VISIBLE_LINES = 8
      COLLAPSE_AFTER = 700

      def initialize(recording:)
        super()
        @recording = recording
        @text = recording.recordable
      end

      def render?
        plain_text.present?
      end

      def body_html
        FlatPack::RichTextSanitizer.sanitize(@text.body.to_s)
      end

      def body_classes
        BODY_CLASSES
      end

      def collapsed_classes
        COLLAPSED_CLASSES
      end

      def fade_classes
        FADE_CLASSES
      end

      def collapsible?
        plain_text.length > COLLAPSE_AFTER
      end

      def body_id
        "presskits-text-body-#{@recording.id}"
      end

      def show_more_label
        I18n.t("recording_studio_presskits.text.show_more")
      end

      def show_less_label
        I18n.t("recording_studio_presskits.text.show_less")
      end

      private

      def plain_text
        Loofah.fragment(body_html.to_s).text.squish
      end
    end
  end
end
