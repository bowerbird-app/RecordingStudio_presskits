# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class KitHeaderComponent < ViewComponent::Base
      def initialize(press_kit_recording:, header_edit_path:)
        super()
        @press_kit_recording = press_kit_recording
        @header_edit_path = header_edit_path
      end

      def region_classes
        EditorChrome.region_classes(header: true)
      end

      def fab_classes
        EditorChrome::FAB_CLASSES
      end

      def fab_offset
        EditorChrome::FAB_OFFSET
      end

      def header_actions_label
        I18n.t("recording_studio_presskits.editor.header_actions")
      end

      def location_label
        I18n.t("recording_studio_presskits.editor.location")
      end

      def style_label
        I18n.t("recording_studio_presskits.editor.style")
      end

      def cover_image_label
        I18n.t("recording_studio_presskits.editor.cover_image")
      end

      def cover_image_path
        return unless CoverImage.enabled?(@press_kit_recording)

        "#{@header_edit_path}#press_kit_cover_image"
      end
    end
  end
end
