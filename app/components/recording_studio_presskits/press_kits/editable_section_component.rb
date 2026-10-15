# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EditableSectionComponent < ViewComponent::Base
      def initialize(section_recording:, content_path:, remove_path:, highlight: false)
        super()
        @section_recording = section_recording
        @content_path = content_path
        @remove_path = remove_path
        @highlight = highlight
      end

      def section_id
        "presskits-section-#{@section_recording.id}"
      end

      def actions_id
        "#{section_id}-actions"
      end

      def reorder_focus_href
        "##{@section_recording.id}"
      end

      def content_visible?
        frame.content_visible?
      end

      def highlight?
        @highlight
      end

      def text_section?
        frame.content_recording&.recordable.is_a?(RecordingStudioPresskits::Text)
      end

      def show_content_edit?
        !text_section?
      end

      def frame
        @frame ||= SectionFrameComponent.new(section_recording: @section_recording)
      end

      def region_classes
        EditorChrome.region_classes(highlight: highlight?)
      end

      def action_row_classes
        EditorChrome::ACTION_ROW_CLASSES
      end

      # TrashButton :sm matches a labeled :sm button's padding and icon, then
      # floors the box at --hit-target-min (2.75rem). Order and Edit do not.
      # Drop that floor so this control is the same height.
      TRASH_SIZE_STYLE = "--hit-target-min: 0px"

      def order_label
        I18n.t("recording_studio_presskits.editor.order")
      end

      def trash_size_style
        TRASH_SIZE_STYLE
      end

      def edit_label
        I18n.t("recording_studio_presskits.editor.edit")
      end

      def editor_size
        helpers.presskits_editor_size_for(frame.content_recording&.recordable_type)
      end

      def inline_heading
        SectionInlineHeadingComponent.new(
          section_recording: @section_recording,
          update_path: @remove_path,
          title_classes: text_title_classes
        )
      end

      def text_title_classes
        return unless text_section?

        TextSectionHeadingComponent::TITLE_CLASSES
      end

      def text_inline
        RecordingStudioPresskits::Text::InlineComponent.new(
          recording: frame.content_recording,
          update_path: @remove_path
        )
      end
    end
  end
end
