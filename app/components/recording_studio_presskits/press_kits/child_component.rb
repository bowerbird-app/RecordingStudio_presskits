# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class ChildComponent < ViewComponent::Base
      def initialize(recording:, remove_path:, edit_path:)
        super()
        @recording = recording
        @remove_path = remove_path
        @edit_path = edit_path
      end

      def row_label
        KitQuery.section_content(@recording)&.type_label || @recording.type_label
      end

      def can_remove?
        @recording.respond_to?(:recording_studio_trashable_trash!)
      end
    end
  end
end
