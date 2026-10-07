# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    class Component < ViewComponent::Base
      include Gallery

      def initialize(recording:)
        super()
        @recording = recording
      end

      def image_recordings
        gallery_images_for(@recording)
      end

      def image_url_for(attachment_recording)
        gallery_image_url(attachment_recording)
      end
    end
  end
end
