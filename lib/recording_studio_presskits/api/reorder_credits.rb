# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class ReorderCredits
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, CreditsSection, "expected a credits section")
        apply_order(context)
        context.recording
      end

      def self.apply_order(context)
        applied = QuoteOrder.new(context.recording, context.params, recordable_type: CreditLine.name)
                            .apply(context.access_grant.actor)
        SectionAction.reject!("Nothing to reorder") unless applied
      end
      private_class_method :apply_order
    end
  end
end
