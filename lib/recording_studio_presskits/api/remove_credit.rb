# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class RemoveCredit
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, CreditLine, "expected a credit in this section")
        Credits.remove!(context.recording, actor: context.access_grant.actor)
        context.recording
      end
    end
  end
end
