# frozen_string_literal: true

module RecordingStudioPresskits
  module KitEditorHelper
    EDITOR_MODAL_ID = "pk-editor"

    def presskits_editor_modal_id
      EDITOR_MODAL_ID
    end

    def presskits_editor_screen_id
      "#{presskits_editor_modal_id}-screen"
    end

    def presskits_editor_dialog?
      respond_to?(:turbo_frame_request_id) && turbo_frame_request_id == presskits_editor_screen_id
    end

    def presskits_editor_open_data
      {
        modal_id: presskits_editor_modal_id,
        turbo_frame: presskits_editor_screen_id
      }
    end

    def presskits_editor_nav(action)
      return {} unless presskits_editor_dialog?

      { fp_nav: action.to_s }
    end

    def from_kit_editor?
      presskits_editor_dialog? || params[:from_kit_editor].present?
    end

    def editor_picker_items
      RecordingStudioPresskits.picker_types.map do |type_name|
        {
          id: type_name,
          label: RecordingStudio.recordable_type_label(type_name),
          icon: type_name.to_s.safe_constantize.try(:section_menu_icon).presence
        }
      end
    end

    def editable_section_for(recording, highlight: false)
      RecordingStudioPresskits::PressKits::EditableSectionComponent.new(
        section_recording: recording,
        heading_path: heading_press_kit_section_path(@press_kit_recording, recording),
        content_path: edit_press_kit_section_path(@press_kit_recording, recording),
        add_path: press_kit_sections_path(@press_kit_recording),
        picker_items: editor_picker_items,
        highlight: highlight
      )
    end

    def sections_order_for
      RecordingStudioPresskits::PressKits::SectionsOrderComponent.new(
        section_recordings: @section_recordings,
        remove_path: ->(recording) { press_kit_section_path(@press_kit_recording, recording) },
        edit_path: ->(recording) { edit_press_kit_section_path(@press_kit_recording, recording) },
        reorder_path: press_kit_order_path(@press_kit_recording)
      )
    end
  end
end
