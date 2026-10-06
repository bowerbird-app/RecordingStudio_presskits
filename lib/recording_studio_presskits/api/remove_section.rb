# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class RemoveSection
      def self.call(context)
        SectionAction.authorize!(context)
        SectionAction.require_recording!(context.recording, KitSection, "expected a kit section")
        context.recording.recording_studio_trashable_trash!(actor: context.access_grant.actor)
      end
    end
  end
end
