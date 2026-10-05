# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class KitEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings:, picker_types:, add_path:, remove_path:, # rubocop:disable Metrics/ParameterLists
                     reorder_path:, edit_path:, header_title:, header_description:)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @picker_types = Array(picker_types)
        @add_path = add_path
        @remove_path = remove_path
        @reorder_path = reorder_path
        @edit_path = edit_path
        @header_title = header_title
        @header_description = header_description
      end

      def header_title
        @header_title.to_s
      end

      def header_description
        @header_description.to_s
      end

      def show_header_preview?
        header_description.present?
      end

      def show_preview?
        @section_recordings.any? || show_header_preview?
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
