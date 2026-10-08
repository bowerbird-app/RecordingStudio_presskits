# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class AddCredit
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, CreditsSection, "expected a credits section")
        add_credit(context)
      end

      def self.add_credit(context)
        credit = Credits.find_for_root(context.recording.root_recording, context.params[:credit_id])
        SectionAction.reject!("That credit is not in this workspace") if credit.blank?

        Credits.add!(
          credits_section_recording: context.recording,
          credit_recording: credit,
          role: context.params[:role],
          actor: context.access_grant.actor
        )
      end
      private_class_method :add_credit
    end
  end
end
