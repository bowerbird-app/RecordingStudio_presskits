# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :video_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def videos
        VideoSection.active_videos(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def edit_path(video_recording)
        helpers.edit_press_kit_section_video_path(kit_recording, kit_section_recording, video_recording)
      end

      def remove_path(video_recording)
        helpers.press_kit_section_video_path(kit_recording, kit_section_recording, video_recording)
      end

      def video_title(video_recording)
        video_recording.recordable.title.presence || "Video"
      end

      def video_url(video_recording)
        video_recording.recordable.url
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
