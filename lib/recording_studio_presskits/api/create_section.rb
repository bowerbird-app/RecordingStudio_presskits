# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class CreateSection
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, PressKit, "expected a press kit")
        record_section(context)
      end

      def self.record_section(context)
        RecordingStudioPresskits.create_section!(
          press_kit_recording: context.recording,
          content_type: context.params[:content_type],
          actor: context.access_grant.actor,
          title: context.params[:title],
          subtitle: context.params[:subtitle]
        )
      rescue ArgumentError => e
        SectionAction.reject!(e.message)
      end
      private_class_method :record_section
    end
  end
end
