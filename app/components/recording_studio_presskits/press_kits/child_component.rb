# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class ChildComponent < ViewComponent::Base
      def initialize(recording:, remove_path:, reorder_path:, edit_path:, previous_id: nil, next_id: nil) # rubocop:disable Metrics/ParameterLists
        super()
        @recording = recording
        @remove_path = remove_path
        @reorder_path = reorder_path
        @edit_path = edit_path
        @previous_id = previous_id
        @next_id = next_id
      end

      def row_label
        "#{@recording.type_label}: #{helpers.presskits_title_for(@recording)}"
      end

      def can_remove?
        @recording.respond_to?(:recording_studio_trashable_trash!)
      end

      def can_move_up?
        @previous_id.present?
      end

      def can_move_down?
        @next_id.present?
      end
    end
  end
end
