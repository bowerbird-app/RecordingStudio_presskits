# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class ShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings:, picker_types: [], add_path: nil, remove_path: nil, # rubocop:disable Metrics/ParameterLists
                     reorder_path: nil, preview_path: nil, public_path: nil, publish_path: nil, edit_path: nil,
                     update_path: nil, editing: false)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @picker_types = Array(picker_types)
        @add_path = add_path
        @remove_path = remove_path
        @reorder_path = reorder_path
        @preview_path = preview_path
        @public_path = public_path
        @publish_path = publish_path
        @edit_path = edit_path
        @update_path = update_path
        @editing = editing
      end

      def live?
        @press_kit_recording.respond_to?(:currently_published?) && @press_kit_recording.currently_published?
      end

      def editing?
        @editing
      end

      def kit_title
        helpers.presskits_title_for(@press_kit_recording)
      end

      def kit_subtitle
        if editing?
          "Add the bits you need, then line them up."
        else
          "What's going out the door."
        end
      end

      def picker_items
        @picker_types.map do |type_name|
          label = RecordingStudio.recordable_type_label(type_name)
          {
            id: type_name,
            label: label
          }
        end
      end
    end
  end
end
