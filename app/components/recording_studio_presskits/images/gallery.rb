# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    module Gallery
      def gallery_images_for(recording)
        return [] unless recording.respond_to?(:images)

        recording.images(per_page: 100)
      end

      def gallery_image_url(attachment_recording)
        file = attachment_recording.recordable&.file
        return unless file&.attached?

        helpers.main_app.url_for(file)
      end
    end
  end
end
