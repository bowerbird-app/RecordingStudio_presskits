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

      def initialize(section_recording:, clipboard_text: nil)
        super()
        @section_recording = section_recording
        @clipboard_text = clipboard_text
        @clipboard_text = clipboard_text_from_section if @clipboard_text.nil?
        @clipboard_text = @clipboard_text.to_s.strip.presence
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

      # Public and owner preview only. The editor heading does not use this component.
      # Outlined pill: secondary is the flat bordered button; sm plus the button
      # radius reads as a pill. The string is the full plain body, not the clamped HTML.
      def clipboard_text_from_section
        content = RecordingStudioPresskits::KitQuery.section_content(@section_recording)
        return unless content&.recordable.is_a?(RecordingStudioPresskits::Text)

        RecordingStudioPresskits::Text.clipboard_text(content.recordable.body)
      end

      def copy_button
        return if @clipboard_text.blank?

        FlatPack::CopyButton::Component.new(
          text: @clipboard_text,
          label: I18n.t("recording_studio_presskits.text.copy"),
          icon: "clipboard-document",
          style: :secondary,
          size: :sm
        )
      end
    end
  end
end
