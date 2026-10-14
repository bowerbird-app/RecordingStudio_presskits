# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastSection
    class ActionsComponent < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def new_path
        helpers.new_press_kit_section_podcast_path(kit_recording, kit_section_recording)
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
