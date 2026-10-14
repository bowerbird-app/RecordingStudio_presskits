# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionInlineHeadingComponent < ViewComponent::Base
      # Same type as Flatpack SectionTitle at :lg. Literals so Tailwind emits them.
      # "text-2xl" "font-semibold" "leading-tight" "text-[var(--surface-content-color)]"
      # "mt-1" "text-base" "text-[var(--surface-muted-content-color)]" "my-6" "min-w-0"
      TITLE_CLASSES = "text-2xl font-semibold text-[var(--surface-content-color)] leading-tight"
      SUBTITLE_CLASSES = "mt-1 text-base text-[var(--surface-muted-content-color)]"

      def initialize(section_recording:, update_path:, title_classes: nil)
        super()
        @section_recording = section_recording
        @update_path = update_path
        @title_class_override = title_classes
      end

      def title
        saved = @section_recording.recordable.title.to_s.strip
        saved.presence || title_placeholder
      end

      def subtitle
        @section_recording.recordable.subtitle.to_s.strip
      end

      def title_placeholder
        RecordingStudioPresskits.default_section_heading(@section_recording)
      end

      def subtitle_placeholder
        I18n.t("recording_studio_presskits.editor.subtitle_placeholder")
      end

      def title_label
        I18n.t("recording_studio_presskits.editor.section_title")
      end

      def subtitle_label
        I18n.t("recording_studio_presskits.editor.section_subtitle")
      end

      def title_classes
        @title_class_override || TITLE_CLASSES
      end

      def subtitle_classes
        SUBTITLE_CLASSES
      end
    end
  end
end
