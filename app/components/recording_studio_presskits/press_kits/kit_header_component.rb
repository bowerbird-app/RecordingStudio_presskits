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

      def action_row_classes
        EditorChrome::ACTION_ROW_CLASSES
      end

      def image_action_classes
        EditorChrome::IMAGE_ACTION_CLASSES
      end

      def edit_label
        I18n.t("recording_studio_presskits.editor.edit")
      end

      def edit_image_label
        I18n.t("recording_studio_presskits.editor.edit_image")
      end

      def cover_image_path
        return unless CoverImage.enabled?(@press_kit_recording)

        "#{@header_edit_path}#press_kit_cover_image"
      end
    end
  end
end
