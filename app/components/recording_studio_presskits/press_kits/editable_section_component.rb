# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EditableSectionComponent < ViewComponent::Base
      def initialize(section_recording:, heading_path:, content_path:, add_path:, remove_path:, picker_items:, highlight: false) # rubocop:disable Metrics/ParameterLists
        super()
        @section_recording = section_recording
        @heading_path = heading_path
        @content_path = content_path
        @add_path = add_path
        @remove_path = remove_path
        @picker_items = Array(picker_items)
        @highlight = highlight
      end

      def section_id
        "presskits-section-#{@section_recording.id}"
      end

      def picker_modal_id
        "presskits-section-picker-after-#{@section_recording.id}"
      end

      def reorder_focus_href
        "##{@section_recording.id}"
      end

      def content_visible?
        frame.content_visible?
      end

      def content_type
        frame.content_recording&.recordable_type
      end

      def highlight?
        @highlight
      end

      def frame
        @frame ||= SectionFrameComponent.new(section_recording: @section_recording)
      end

      def region_classes
        helpers.presskits_editor_region_classes(highlight: highlight?)
      end

      def fab_classes
        helpers.presskits_editor_fab_classes
      end

      def edit_title_label
        I18n.t("recording_studio_presskits.editor.edit_title")
      end

      def edit_content_label
        I18n.t("recording_studio_presskits.editor.edit_content")
      end

      def section_actions_label
        I18n.t("recording_studio_presskits.editor.section_actions")
      end

      def reorder_label
        I18n.t("recording_studio_presskits.editor.reorder")
      end

      def trash_label
        I18n.t("recording_studio_presskits.editor.trash")
      end

      def trash_confirm
        I18n.t("recording_studio_presskits.editor.trash_confirm")
      end

      def add_new_section_label
        I18n.t("recording_studio_presskits.editor.add_new_section")
      end
    end
  end
end
