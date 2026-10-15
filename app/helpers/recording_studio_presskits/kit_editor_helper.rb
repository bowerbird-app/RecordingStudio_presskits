# frozen_string_literal: true

module RecordingStudioPresskits
  module KitEditorHelper
    # lg keeps the original id so existing screens and tests still address it.
    EDITOR_MODAL_ID = "pk-editor"
    EDITOR_MODAL_SIZES = {
      "md" => "pk-editor-md",
      "lg" => EDITOR_MODAL_ID,
      "xl" => "pk-editor-xl",
      "2xl" => "pk-editor-2xl"
    }.freeze
    SECTION_MODAL_SIZES = {
      "RecordingStudioPresskits::CreditsSection" => "2xl",
      "RecordingStudioPresskits::ListSection" => "xl",
      "RecordingStudioPresskits::Images" => "xl",
      "RecordingStudioPresskits::MenuSection" => "md"
    }.freeze

    def presskits_editor_modal_ids
      EDITOR_MODAL_SIZES.values
    end

    def presskits_editor_modal_id_for(size)
      EDITOR_MODAL_SIZES.fetch(size.to_s)
    end

    def presskits_editor_size_for(type_name)
      SECTION_MODAL_SIZES.fetch(type_name.to_s, "lg")
    end

    def presskits_editor_modal_id
      requested = presskits_editor_modal_ids.find { |modal_id| editor_frame_id == "#{modal_id}-screen" }
      requested || EDITOR_MODAL_ID
    end

    # Navigable screens require a title. A zero-width space leaves the chrome
    # heading empty so PageTitle is the only visible heading.
    def presskits_editor_blank_chrome_title
      "\u200B"
    end

    def presskits_editor_screen_id
      "#{presskits_editor_modal_id}-screen"
    end

    def presskits_editor_dialog?
      return false unless respond_to?(:request) && request

      presskits_editor_modal_ids.any? { |modal_id| editor_frame_id == "#{modal_id}-screen" }
    end

    def presskits_editor_open_data(size: :lg)
      modal_id = presskits_editor_modal_id_for(size)
      {
        modal_id: modal_id,
        turbo_frame: "#{modal_id}-screen"
      }
    end

    def presskits_editor_nav(action)
      return {} unless presskits_editor_dialog?

      { fp_nav: action.to_s }
    end

    # Turbo Streams refresh the preview behind the modal. Target `_top` so the
    # navigable screen frame does not swallow the response and sit on loading.
    def presskits_editor_save_data
      data = { turbo_stream: true }
      data[:turbo_frame] = "_top" if presskits_editor_dialog?
      data
    end

    def from_kit_editor?
      presskits_editor_dialog? || params[:from_kit_editor].present?
    end

    def editor_picker_items
      RecordingStudioPresskits.picker_types.map do |type_name|
        {
          id: type_name,
          label: RecordingStudio.recordable_type_label(type_name),
          icon: type_name.to_s.safe_constantize.try(:section_menu_icon).presence,
          description: picker_description_for(type_name)
        }
      end
    end

    def picker_description_for(type_name)
      key = type_name.to_s.demodulize.underscore
      I18n.t(
        "recording_studio_presskits.editor.picker_descriptions.#{key}",
        default: I18n.t("recording_studio_presskits.editor.picker_descriptions.generic")
      )
    end

    def editable_section_for(recording, highlight: false)
      RecordingStudioPresskits::PressKits::EditableSectionComponent.new(
        section_recording: recording,
        content_path: edit_press_kit_section_path(@press_kit_recording, recording),
        remove_path: press_kit_section_path(@press_kit_recording, recording),
        highlight: highlight
      )
    end

    def editor_frame_id
      return "" unless respond_to?(:request) && request

      request.headers["Turbo-Frame"].to_s
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
