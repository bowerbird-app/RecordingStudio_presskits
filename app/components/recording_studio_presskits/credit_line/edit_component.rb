# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditLine
    class EditComponent < ViewComponent::Base
      def initialize(line_recording:, section_recording:, credit_recording:)
        super()
        @line_recording = line_recording
        @section_recording = section_recording
        @credit_recording = credit_recording
      end

      def line
        @line_recording.recordable
      end

      def credit_name
        return "In the trash" unless Credits.shown_credit?(@credit_recording)

        @credit_recording.recordable.name
      end

      def credit_edit_path
        return unless Credits.shown_credit?(@credit_recording)

        helpers.edit_credit_path(@credit_recording)
      end

      def update_path
        helpers.press_kit_section_credit_path(kit_recording, @section_recording, @line_recording)
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
