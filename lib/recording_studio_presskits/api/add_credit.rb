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
        name = context.params[:name].to_s.strip
        SectionAction.reject!("Give them a name.") if name.blank?

        Credits.add!(
          credits_section_recording: context.recording,
          name: name,
          url: context.params[:url],
          role: context.params[:role],
          actor: context.access_grant.actor
        )
      end
      private_class_method :add_credit
    end
  end
end
