# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class ShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings:, picker_types:, add_path:, remove_path:, reorder_path:, # rubocop:disable Metrics/ParameterLists
                     preview_path: nil, public_path: nil, publish_path: nil)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @picker_types = picker_types
        @add_path = add_path
        @remove_path = remove_path
        @reorder_path = reorder_path
        @preview_path = preview_path
        @public_path = public_path
        @publish_path = publish_path
      end

      def live?
        @press_kit_recording.respond_to?(:currently_published?) && @press_kit_recording.currently_published?
      end

      def kit_title
        helpers.presskits_title_for(@press_kit_recording)
      end

      def picker_items
        @picker_types.map do |type_name|
          label = RecordingStudio.recordable_type_label(type_name)
          {
            id: type_name,
            kind: "record",
            name: label,
            label: label,
            title: label
          }
        end
      end
    end
  end
end
