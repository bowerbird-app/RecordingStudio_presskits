# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class PublicShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings: nil, preview: false)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @preview = preview
      end

      def kit_title
        recordable = @press_kit_recording&.recordable
        recordable&.try(:title).presence || @press_kit_recording&.try(:name).presence || "Press kit"
      end

      def section_title(recording)
        recordable = recording&.recordable
        recordable&.try(:title).presence || recording&.try(:name).presence || recording&.type_label
      end

      def section_recordings
        @section_recordings || KitQuery.live_children(@press_kit_recording)
      end

      def preview?
        @preview
      end

      def live?
        @press_kit_recording.respond_to?(:currently_published?) && @press_kit_recording.currently_published?
      end

      def section_component_for(recording)
        RecordingStudioPresskits.section_component_for(recording)
      end
    end
  end
end
