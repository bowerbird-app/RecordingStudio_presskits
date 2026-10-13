# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EditableSectionComponent < ViewComponent::Base
      # Tailwind scans these literals. Desktop hides the row until hover or focus.
      # Narrow widths and touch keep it visible.
      # "opacity-0" "pointer-events-none" "transition-opacity" "duration-[var(--duration-base)]"
      # "[@media(hover:hover)]:group-hover/pk-edit:opacity-100"
      # "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto"
      # "group-focus-within/pk-edit:opacity-100" "group-focus-within/pk-edit:pointer-events-auto"
      # "focus-within:opacity-100" "focus-within:pointer-events-auto"
      # "[@media(hover:none)]:opacity-100" "[@media(hover:none)]:pointer-events-auto"
      # "max-sm:opacity-100" "max-sm:pointer-events-auto"
      # "self-end" "sm:self-auto"
      ACTION_ROW_CLASSES = [
        "flex shrink-0 flex-wrap items-center justify-end gap-2 self-end sm:self-auto",
        "opacity-0 pointer-events-none",
        "transition-opacity duration-[var(--duration-base)]",
        "[@media(hover:hover)]:group-hover/pk-edit:opacity-100",
        "[@media(hover:hover)]:group-hover/pk-edit:pointer-events-auto",
        "group-focus-within/pk-edit:opacity-100 group-focus-within/pk-edit:pointer-events-auto",
        "focus-within:opacity-100 focus-within:pointer-events-auto",
        "[@media(hover:none)]:opacity-100 [@media(hover:none)]:pointer-events-auto",
        "max-sm:opacity-100 max-sm:pointer-events-auto"
      ].join(" ").freeze

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
        ACTION_ROW_CLASSES
      end

      # TrashButton :sm matches a labeled :sm button's padding and icon, then
      # floors the box at --hit-target-min (2.75rem). Order and Edit do not.
      # Drop that floor so this control is the same height.
      TRASH_SIZE_STYLE = "--hit-target-min: 0px"

      # Below sm, Edit and Order show the icon only. The label span stays in
      # the tree (sr-only) and aria-label names the control. icon_only: adds
      # fp-hit-target, which floors the box at 2.75rem.
      # "max-sm:px-[var(--button-icon-only-padding-sm)]" "max-sm:[&>span]:sr-only"
      MOBILE_ICON_CLASSES = "max-sm:px-[var(--button-icon-only-padding-sm)] max-sm:[&>span]:sr-only"

      def order_label
        I18n.t("recording_studio_presskits.editor.order")
      end

      def trash_size_style
        TRASH_SIZE_STYLE
      end

      def mobile_icon_classes
        MOBILE_ICON_CLASSES
      end

      def edit_label
        I18n.t("recording_studio_presskits.editor.edit")
      end

      def inline_heading
        SectionInlineHeadingComponent.new(
          section_recording: @section_recording,
          update_path: @remove_path
        )
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
