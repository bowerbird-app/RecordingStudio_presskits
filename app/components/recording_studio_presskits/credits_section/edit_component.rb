# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :credits_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def lines
        Credits.lines_for(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def order_path
        helpers.press_kit_section_credit_order_path(kit_recording, kit_section_recording)
      end

      def edit_path(line_recording)
        helpers.edit_press_kit_section_credit_path(kit_recording, kit_section_recording, line_recording)
      end

      def remove_path(line_recording)
        helpers.press_kit_section_credit_path(kit_recording, kit_section_recording, line_recording)
      end

      def line_role(line_recording)
        line_recording.recordable.role.to_s.strip.presence || "Credit"
      end

      def line_name(line_recording)
        credit = Credits.credit_for(line_recording)
        return "In the trash" unless Credits.shown_credit?(credit)

        credit.recordable.name.to_s.strip.presence
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
