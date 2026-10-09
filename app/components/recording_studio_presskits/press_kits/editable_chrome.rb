# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    # Hover must use `&:hover`, not Tailwind's `hover:` / `group-hover:` variants.
    # Those compile behind `@media (hover: hover)` and stay off on coarse pointers.
    module EditableChrome
      BLOCK_CLASS = [
        "presskits-editable",
        "relative rounded-[var(--radius-lg)] p-4 -mx-4",
        "outline outline-2 outline-transparent",
        "transition-[outline-color] duration-[var(--duration-base)]",
        "[&:hover]:outline-[var(--color-primary)]",
        "focus-within:outline-[var(--color-primary)]"
      ].join(" ").freeze

      CONTROLS_CLASS = [
        "presskits-section-edits",
        "opacity-0 transition-opacity duration-[var(--duration-base)]",
        "[.presskits-editable:hover_&]:opacity-100",
        "[.presskits-editable:focus-within_&]:opacity-100"
      ].join(" ").freeze
    end
  end
end
