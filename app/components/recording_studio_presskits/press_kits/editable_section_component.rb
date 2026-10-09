# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EditableSectionComponent < ViewComponent::Base
      def initialize(section_recording:, heading_path:, content_path:, add_path:, picker_items:, highlight: false) # rubocop:disable Metrics/ParameterLists
        super()
        @section_recording = section_recording
        @heading_path = heading_path
        @content_path = content_path
        @add_path = add_path
        @picker_items = Array(picker_items)
        @highlight = highlight
      end

      def section_id
        "presskits-section-#{@section_recording.id}"
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

      def edit_heading_label
        I18n.t("recording_studio_presskits.editor.edit_heading")
      end

      def edit_content_label
        I18n.t("recording_studio_presskits.editor.edit_content")
      end

      def chrome_class
        highlight? ? "#{EditableChrome::BLOCK_CLASS} ring-2 ring-[var(--color-primary)]" : EditableChrome::BLOCK_CLASS
      end

      def controls_class
        EditableChrome::CONTROLS_CLASS
      end
    end
  end
end
