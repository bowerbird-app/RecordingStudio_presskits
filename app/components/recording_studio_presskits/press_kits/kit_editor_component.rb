# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class KitEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings:, picker_types:, add_path:, remove_path:, # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
                     reorder_path:, edit_path:, heading_path:, header_edit_path:, download_edit_path: nil,
                     highlight_id: nil)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @picker_types = Array(picker_types)
        @add_path = add_path
        @remove_path = remove_path
        @reorder_path = reorder_path
        @edit_path = edit_path
        @heading_path = heading_path
        @header_edit_path = header_edit_path
        @download_edit_path = download_edit_path
        @highlight_id = highlight_id
      end

      def picker_items
        @picker_types.map do |type_name|
          {
            id: type_name,
            label: RecordingStudio.recordable_type_label(type_name),
            icon: section_menu_icon_for(type_name),
            description: picker_description_for(type_name)
          }
        end
      end

      def highlight?(recording)
        recording.id.to_s == @highlight_id.to_s
      end

      private

      def section_menu_icon_for(type_name)
        type_name.to_s.safe_constantize.try(:section_menu_icon).presence
      end

      def picker_description_for(type_name)
        key = type_name.to_s.demodulize.underscore
        I18n.t(
          "recording_studio_presskits.editor.picker_descriptions.#{key}",
          default: I18n.t("recording_studio_presskits.editor.picker_descriptions.generic")
        )
      end
    end
  end
end
