# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    # Public and owner-preview heading for a text section.
    # Other section types stay on SectionHeadingComponent / SectionTitle.
    class TextSectionHeadingComponent < ViewComponent::Base
      # 32px, bold, theme content colour. Tracking matches the text-block design.
      # Tailwind scans these literals:
      # "text-[2rem]" "font-bold" "leading-[normal]" "tracking-[-0.015em]"
      # "text-[var(--surface-content-color)]"
      TITLE_CLASSES = [
        "text-[2rem] font-bold leading-[normal] tracking-[-0.015em]",
        "text-[var(--surface-content-color)]"
      ].join(" ").freeze

      # "mt-1" "text-base" "text-[var(--surface-muted-content-color)]"
      SUBTITLE_CLASSES = "mt-1 text-base text-[var(--surface-muted-content-color)]"

      def initialize(section_recording:)
        super()
        @section_recording = section_recording
      end

      def title
        RecordingStudioPresskits.section_heading(@section_recording)
      end

      def subtitle
        @section_recording.recordable.subtitle.to_s.strip.presence
      end

      def title_classes
        TITLE_CLASSES
      end

      def subtitle_classes
        SUBTITLE_CLASSES
      end
    end
  end
end
