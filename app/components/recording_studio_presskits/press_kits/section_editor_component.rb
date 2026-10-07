# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionEditorComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @section = recording
        @update_path = update_path
      end

      def page_title
        content_recording&.type_label || @section.type_label
      end

      def section_title
        @section.recordable.title
      end

      def section_subtitle
        @section.recordable.subtitle
      end

      def cancel_path
        helpers.edit_press_kit_path(@section.parent_recording)
      end

      def attachment_return_path
        helpers.edit_press_kit_section_path(@section.parent_recording, @section)
      end

      def form?
        editor = editor_class
        return false unless editor
        return true unless editor.respond_to?(:form?)

        editor.form?
      end

      def content_recording
        @content_recording ||= KitQuery.section_content(@section)
      end

      def editor_view
        @editor_view ||= editor_class&.new(recording: content_recording, update_path: @update_path)
      end

      def editor_class
        return if content_recording.blank?

        RecordingStudioPresskits.section_editor_for(content_recording)
      end
    end
  end
end
