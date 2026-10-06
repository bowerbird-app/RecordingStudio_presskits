# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionEditorComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      def cancel_path
        helpers.edit_press_kit_path(@recording.parent_recording)
      end

      def show_preview?
        editor = editor_class
        return true unless editor.respond_to?(:preview?)

        editor.preview?
      end

      def form?
        editor = editor_class
        return false unless editor
        return true unless editor.respond_to?(:form?)

        editor.form?
      end

      def grid_cols
        show_preview? ? 2 : 1
      end

      def editor_view
        @editor_view ||= editor_class&.new(recording: @recording, update_path: @update_path)
      end

      def editor_class
        RecordingStudioPresskits.section_editor_for(@recording)
      end
    end
  end
end
