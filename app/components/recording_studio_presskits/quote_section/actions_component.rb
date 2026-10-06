# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteSection
    class ActionsComponent < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def add_path
        helpers.press_kit_section_quotes_path(kit_recording, kit_section_recording)
      end

      def cancel_path
        helpers.edit_press_kit_path(kit_recording)
      end

      private

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
