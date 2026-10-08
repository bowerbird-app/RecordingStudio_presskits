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
        content_recording&.type_label || @recording.type_label
      end

      def row_icon
        content_recording&.recordable_type.to_s.safe_constantize.try(:section_menu_icon).presence
      end

      def can_remove?
        @recording.respond_to?(:recording_studio_trashable_trash!)
      end

      private

      def content_recording
        @content_recording ||= KitQuery.section_content(@recording)
      end
    end
  end
end
