# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    module EditorChrome
      CONTROLLER = "recording-studio-presskits--editor-chrome"
      FAB_OFFSET = "1rem"
      FAB_RESERVE_CLASS = "pr-20 md:pr-20 lg:pr-20"
      KIT_CARD_CLASSES = "w-full overflow-hidden"
      PREVIEW_CLASSES = "flex w-full flex-col overflow-hidden rounded-[var(--radius-lg)]"
      KIT_SECTIONS_CLASSES = "flex w-full flex-col gap-6 p-5 md:p-8 lg:p-10"

      # Split p-8 / md:p-10 / lg:p-12 so pr-20 still wins on the right.
      REGION_CLASSES = [
        "group/pk-edit relative rounded-[var(--radius-lg)] bg-transparent",
        "pt-8 pb-8 px-8 md:pt-10 md:pb-10 md:px-10 lg:pt-12 lg:pb-12 lg:px-12",
        "transition-colors duration-[var(--duration-base)]",
        "[@media(hover:hover)]:hover:bg-[var(--surface-muted-background-color)]",
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

      FAB_CLASSES = [
        "z-20 opacity-0 pointer-events-none",
        "transition-opacity duration-[var(--duration-base)]",
        "[@media(hover:hover)]:group-hover/pk-edit:opacity-100",
        "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto",
        "group-focus-within/pk-edit:opacity-100 group-focus-within/pk-edit:pointer-events-auto",
        "focus-within:opacity-100 focus-within:pointer-events-auto",
        "[@media(hover:none)]:group-data-[pk-edit-active]/pk-edit:opacity-100",
        "[@media(hover:none)]:group-data-[pk-edit-active]/pk-edit:pointer-events-auto"
      ].join(" ").freeze

      def self.region_classes(highlight: false, reserve_fab: false, header: false)
        classes = header ? HEADER_REGION_CLASSES : REGION_CLASSES
        classes = "#{classes} #{FAB_RESERVE_CLASS}" if reserve_fab
        return classes unless highlight

        "#{classes} #{HIGHLIGHT_CLASSES}"
      end
    end
  end
end
