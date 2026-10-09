# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    module EditorChrome
      CONTROLLER = "recording-studio-presskits--editor-chrome"

      REGION_CLASSES = [
        "group/pk-edit relative rounded-[var(--radius-lg)] bg-transparent",
        "transition-colors duration-[var(--duration-base)]",
        "[@media(hover:hover)]:hover:bg-[var(--surface-muted-background-color)]",
        "focus-within:bg-[var(--surface-muted-background-color)]",
        "[@media(hover:none)]:data-[pk-edit-active]:bg-[var(--surface-muted-background-color)]",
        "outline-none focus-visible:outline focus-visible:outline-2",
        "focus-visible:outline-[var(--color-primary)]"
      ].join(" ").freeze

      HIGHLIGHT_CLASSES = "ring-2 ring-[var(--color-primary)]"

      FAB_CLASSES = [
        "opacity-0 pointer-events-none",
        "transition-opacity duration-[var(--duration-base)]",
        "[@media(hover:hover)]:group-hover/pk-edit:opacity-100",
        "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto",
        "group-focus-within/pk-edit:opacity-100 group-focus-within/pk-edit:pointer-events-auto",
        "focus-within:opacity-100 focus-within:pointer-events-auto",
        "[@media(hover:none)]:group-data-[pk-edit-active]/pk-edit:opacity-100",
        "[@media(hover:none)]:group-data-[pk-edit-active]/pk-edit:pointer-events-auto"
      ].join(" ").freeze

      def self.region_classes(highlight: false)
        return REGION_CLASSES unless highlight

        "#{REGION_CLASSES} #{HIGHLIGHT_CLASSES}"
      end
    end
  end
end
