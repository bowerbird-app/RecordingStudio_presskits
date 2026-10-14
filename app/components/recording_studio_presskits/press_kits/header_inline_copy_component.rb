# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderInlineCopyComponent < ViewComponent::Base
      # Same type as the wide card title, subtitle, and description.
      # "text-[30px]" "font-bold" "leading-[38px]" "tracking-[-0.45px]" "text-balance"
      # "font-normal" "text-base" "leading-6" "text-[var(--surface-muted-content-color)]"
      # "relative" "z-20" "min-w-0" "gap-[14px]" "gap-0.5" "hidden @min-[640px]:block"
      TITLE_CLASSES = "text-[30px] font-bold leading-[38px] tracking-[-0.45px] text-balance"
      SUBTITLE_CLASSES = "text-[30px] font-normal leading-[38px] tracking-[-0.45px]"
      DESCRIPTION_CLASSES = "text-base leading-6 text-[var(--surface-muted-content-color)]"

      def initialize(recording:, update_path:, heading: :h1, context: :header)
        super()
        @recording = recording
        @update_path = update_path
        @heading = %i[h1 h2].include?(heading&.to_sym) ? heading.to_sym : :h2
        @context = context.to_sym
      end

      def description_frame_classes
        "hidden @min-[640px]:block" if @context == :grid
      end

      def title
        recordable&.try(:title).to_s.strip
      end

      def subtitle
        recordable&.try(:subtitle).to_s.strip
      end

      def description
        recordable&.try(:description).to_s.strip
      end

      def title_label
        I18n.t("recording_studio_presskits.editor.kit_title")
      end

      def subtitle_label
        I18n.t("recording_studio_presskits.editor.kit_subtitle")
      end

      def description_label
        I18n.t("recording_studio_presskits.editor.kit_description")
      end

      def title_placeholder
        I18n.t("recording_studio_presskits.editor.title_placeholder")
      end

      def subtitle_placeholder
        I18n.t("recording_studio_presskits.editor.subtitle_placeholder")
      end

      def description_placeholder
        I18n.t("recording_studio_presskits.editor.description_placeholder")
      end

      def title_classes
        TITLE_CLASSES
      end

      def subtitle_classes
        SUBTITLE_CLASSES
      end

      def description_classes
        DESCRIPTION_CLASSES
      end

      def heading_tag
        @heading
      end

      private

      def recordable
        @recording&.recordable
      end
    end
  end
end
