# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class ReorderChildren
      def self.call(context)
        SectionAction.authorize!(context)
        ids = Array(context.params[:ordered_recording_ids])
        SectionAction.reject!("ordered_recording_ids is required") if ids.empty?

        context.recording.recording_studio_orderable_reorder!(
          ordered_recording_ids: ids,
          actor: context.access_grant.actor
        )
        context.recording
      end
    end
  end
end
