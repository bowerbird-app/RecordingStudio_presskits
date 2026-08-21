# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class ChildComponent < ViewComponent::Base
      def initialize(recording:, index:, total:, remove_path:, reorder_path:)
        super()
        @recording = recording
        @index = index
        @total = total
        @remove_path = remove_path
        @reorder_path = reorder_path
      end

      def section_component
        RecordingStudioPresskits.section_component_for(@recording)
      end

      def can_remove?
        @recording.respond_to?(:recording_studio_trashable_trash!)
      end

      def can_move_up?
        @index.positive?
      end

      def can_move_down?
        @index < (@total - 1)
      end
    end
  end
end
