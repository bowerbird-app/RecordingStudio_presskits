# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    module EditorChrome
      CONTROLLER = "recording-studio-presskits--editor-chrome"
      KIT_CARD_CLASSES = "w-full overflow-hidden"
      # Tailwind scans this literal: "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
      SECTION_CARD_CLASSES = "w-full shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
      PREVIEW_CLASSES = "flex w-full flex-col gap-6"
      KIT_SECTIONS_CLASSES = "flex w-full flex-col gap-6"
      # Pad stays inside each card. The stack gap is the space between cards.
      SECTION_PAD_CLASSES = "pt-8 pb-8 px-8 md:pt-10 md:pb-10 md:px-10 lg:pt-12 lg:pb-12 lg:px-12"

      REGION_CLASSES = [
        "group/pk-edit relative w-full rounded-[var(--radius-lg)] bg-transparent",
        SECTION_PAD_CLASSES,
        "transition-colors duration-[var(--duration-base)]",
        "focus-within:bg-[var(--surface-muted-background-color)]",
        "[@media(hover:none)]:data-[pk-edit-active]:bg-[var(--surface-muted-background-color)]",
        "outline-none focus-visible:outline focus-visible:outline-2",
        "focus-visible:outline-[var(--color-primary)]"
      ].join(" ").freeze

      # Overlay hover, not a surrounding tint — the hero must stay flush to the card.
      HEADER_REGION_CLASSES = [
        "group/pk-edit relative w-full",
        "outline-none",
        "after:pointer-events-none after:absolute after:inset-0 after:z-10 after:content-['']",
        "after:bg-transparent after:transition-colors after:duration-[var(--duration-base)]",
        "[@media(hover:hover)]:hover:after:bg-[color-mix(in_oklab,black_16%,transparent)]",
        "focus-within:after:bg-[color-mix(in_oklab,black_16%,transparent)]",
        "[@media(hover:none)]:data-[pk-edit-active]:after:bg-[color-mix(in_oklab,black_16%,transparent)]",
        "focus-visible:outline focus-visible:outline-2",
        "focus-visible:outline-[var(--color-primary)]"
      ].join(" ").freeze

      HIGHLIGHT_CLASSES = "ring-2 ring-[var(--color-primary)]"

      # Desktop hides the row until hover or focus. Narrow widths and touch keep it visible.
      # Tailwind scans these literals: "opacity-0" "pointer-events-none" "transition-opacity"
      # "duration-[var(--duration-base)]"
      # "[@media(hover:hover)]:group-hover/pk-edit:opacity-100"
      # "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto"
      # "group-focus-within/pk-edit:opacity-100" "group-focus-within/pk-edit:pointer-events-auto"
      # "focus-within:opacity-100" "focus-within:pointer-events-auto"
      # "[@media(hover:none)]:opacity-100" "[@media(hover:none)]:pointer-events-auto"
      # "max-sm:opacity-100" "max-sm:pointer-events-auto"
      ACTION_VISIBILITY_CLASSES = [
        "opacity-0 pointer-events-none",
        "transition-opacity duration-[var(--duration-base)]",
        "[@media(hover:hover)]:group-hover/pk-edit:opacity-100",
        "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto",
        "group-focus-within/pk-edit:opacity-100 group-focus-within/pk-edit:pointer-events-auto",
        "focus-within:opacity-100 focus-within:pointer-events-auto",
        "[@media(hover:none)]:opacity-100 [@media(hover:none)]:pointer-events-auto",
        "max-sm:opacity-100 max-sm:pointer-events-auto"
      ].join(" ").freeze

      # Beside a title. On a column, self-end keeps the row at the trailing edge.
      # Tailwind scans these literals: "self-end" "sm:self-auto"
      ACTION_ROW_CLASSES = [
        "flex shrink-0 flex-wrap items-center justify-end gap-2 self-end sm:self-auto",
        ACTION_VISIBILITY_CLASSES
      ].join(" ").freeze

      # On the cover image. The bar already aligns to the top, so self-end would
      # drop this row to the bottom of the badge.
      IMAGE_ACTION_CLASSES = [
        "flex shrink-0 flex-wrap items-center justify-end gap-2",
        ACTION_VISIBILITY_CLASSES
      ].join(" ").freeze

      # Below sm the label span stays in the tree (sr-only) and aria-label names the control.
      # icon_only: adds fp-hit-target, which floors the box at 2.75rem.
      # "max-sm:px-[var(--button-icon-only-padding-sm)]" "max-sm:[&>span]:sr-only"
      MOBILE_ICON_CLASSES = "max-sm:px-[var(--button-icon-only-padding-sm)] max-sm:[&>span]:sr-only"

      def self.region_classes(highlight: false, header: false)
        classes = header ? HEADER_REGION_CLASSES : REGION_CLASSES
        return classes unless highlight

        "#{classes} #{HIGHLIGHT_CLASSES}"
      end
    end
  end
end
