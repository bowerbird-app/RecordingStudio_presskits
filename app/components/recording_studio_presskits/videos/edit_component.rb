# frozen_string_literal: true

module RecordingStudioPresskits
  module Videos
    class EditComponent < ViewComponent::Base
      attr_reader :video

      def initialize(video:, section_recording:, video_recording: nil)
        super()
        @video = video
        @section_recording = section_recording
        @video_recording = video_recording
      end

      def heading
        video.title.presence || "Video"
      end

      def fields
        helpers.recording_studio_video_fields(video)
      end

      def player
        return unless @video_recording&.persisted? && video.content_type == "video"

        helpers.recording_studio_video_player(@video_recording)
      end

      def form_path
        if @video_recording&.persisted?
          helpers.press_kit_section_video_path(kit_recording, @section_recording, @video_recording)
        else
          helpers.press_kit_section_videos_path(kit_recording, @section_recording)
        end
      end

      def form_method
        @video_recording&.persisted? ? :patch : :post
      end

      def form_data
        @video_recording&.persisted? ? { turbo_stream: true } : {}
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
