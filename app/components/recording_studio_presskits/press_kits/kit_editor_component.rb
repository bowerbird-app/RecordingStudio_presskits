# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class KitEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings:, picker_types:, add_path:, remove_path:, # rubocop:disable Metrics/ParameterLists
                     reorder_path:, update_path:, edit_path:)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @picker_types = Array(picker_types)
        @add_path = add_path
        @remove_path = remove_path
        @reorder_path = reorder_path
        @update_path = update_path
        @edit_path = edit_path
      end

      def picker_items
        @picker_types.map do |type_name|
          {
            id: type_name,
            label: RecordingStudio.recordable_type_label(type_name)
          }
        end
      end
    end
  end
end
