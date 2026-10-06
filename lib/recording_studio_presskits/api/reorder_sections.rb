# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class ReorderSections
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, PressKit, "expected a press kit")
        apply_order(context)
      end

      def self.apply_order(context)
        ids = Array(context.params[:ordered_recording_ids])
        SectionAction.reject!("ordered_recording_ids is required") if ids.empty?

        context.recording.recording_studio_orderable_reorder!(
          ordered_recording_ids: ids,
          actor: context.access_grant.actor
        )
      end
      private_class_method :apply_order
    end
  end
end
