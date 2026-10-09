# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class KitHeaderComponent < ViewComponent::Base
      def initialize(press_kit_recording:, header_edit_path:)
        super()
        @press_kit_recording = press_kit_recording
        @header_edit_path = header_edit_path
      end

      def page_title_options
        options = { title: kit_title, variant: :h1 }
        options[:subtitle] = kit_description if kit_description.present?
        options
      end

      def kit_title
        recordable = @press_kit_recording.recordable
        recordable&.try(:title).presence || @press_kit_recording.try(:name).presence || "Press kit"
      end

      def kit_description
        @press_kit_recording.recordable.try(:description).to_s.strip.presence
      end

      def region_classes
        EditorChrome.region_classes
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

      def edit_heading_label
        I18n.t("recording_studio_presskits.editor.edit_heading")
      end

      def cover_colours_label
        I18n.t("recording_studio_presskits.editor.cover_colours")
      end
    end
  end
end
