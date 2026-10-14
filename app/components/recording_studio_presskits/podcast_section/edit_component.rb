# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :podcast_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def podcasts
        PodcastSection.active_podcasts(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def edit_path(podcast_recording)
        helpers.edit_press_kit_section_podcast_path(kit_recording, kit_section_recording, podcast_recording)
      end

      def remove_path(podcast_recording)
        helpers.press_kit_section_podcast_path(kit_recording, kit_section_recording, podcast_recording)
      end

      def podcast_title(podcast_recording)
        podcast_recording.recordable.episode_title
      end

      def podcast_url(podcast_recording)
        podcast_recording.recordable.url
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
