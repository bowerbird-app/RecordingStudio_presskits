# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class AddComponent < ViewComponent::Base
      def initialize(credit:, root_recording:, url:, kit_role:)
        super()
        @credit = credit
        @root_recording = root_recording
        @url = url
        @kit_role = kit_role
      end

      def credits
        @credits ||= Credits.active_for_root(@root_recording).to_a
      end

      def credit_options
        credits.map { |recording| [choice_label(recording), recording.id] }
      end

      def credits_payload
        credits.map { |recording| payload_for(recording) }
      end

      def new_kit_role
        @kit_role.to_s.strip.presence || @credit.usual_role
      end

      def create_button_style
        credits.any? ? :secondary : :primary
      end

      def subtitle
        return "Pick someone from this workspace, or add someone new." if credits.any?

        "Saved for this workspace, then added to this kit."
      end

      private

      def payload_for(recording)
        credit = recording.recordable
        { id: recording.id.to_s, name: credit.name.to_s, usual_role: credit.usual_role.to_s }
      end

      def choice_label(recording)
        credit = recording.recordable
        [credit.name, credit.usual_role].filter_map { |value| value.to_s.strip.presence }.join(", ")
      end
    end
  end
end
