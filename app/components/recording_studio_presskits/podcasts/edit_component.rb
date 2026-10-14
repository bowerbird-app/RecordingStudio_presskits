# frozen_string_literal: true

module RecordingStudioPresskits
  module Podcasts
    class EditComponent < ViewComponent::Base
      attr_reader :podcast

      def initialize(podcast:, section_recording:, podcast_recording: nil)
        super()
        @podcast = podcast
        @section_recording = section_recording
        @podcast_recording = podcast_recording
      end

      def heading
        podcast.episode_title
      end

      def persisted?
        @podcast_recording&.persisted?
      end

      def form_path
        if persisted?
          helpers.press_kit_section_podcast_path(kit_recording, @section_recording, @podcast_recording)
        else
          helpers.press_kit_section_podcasts_path(kit_recording, @section_recording)
        end
      end

      def form_method
        persisted? ? :patch : :post
      end

      def form_data
        data = persisted? ? helpers.presskits_editor_save_data : {}
        return data unless persisted?

        data.merge(upload.data)
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      def image_path
        return unless persisted?

        helpers.press_kit_section_podcast_image_path(kit_recording, @section_recording, @podcast_recording)
      end

      def cover_url
        return unless persisted?

        PodcastArtwork.image_url(@podcast_recording, helpers: helpers)
      end

      def uploaded_cover?
        persisted? && PodcastArtwork.uploaded?(@podcast_recording)
      end

      def aired_on_value
        podcast.aired_on&.iso8601
      end

      private

      def upload
        Upload.new(helpers, @section_recording, @podcast_recording)
      end

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
