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

      def section_title_fallback
        RecordingStudioPresskits.default_section_heading(@section)
      end

      def section_subtitle
        @section.recordable.subtitle
      end

      def attachment_return_path
        helpers.edit_press_kit_section_path(@section.parent_recording, @section)
      end

      def fields_in_form?
        editor_class.present? && !below_editor?
      end

      def below_editor?
        editor = editor_class
        return false unless editor.respond_to?(:below?)

        editor.below?
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

      def show_preview?
        SectionFrameComponent.new(section_recording: @section).render?
      end

      def update_button
        FlatPack::Button::Component.new(
          text: "Update",
          style: :default,
          type: "submit",
          data: { "flat-pack--unsaved-changes-target": "submit" }
        )
      end
    end
  end
end
