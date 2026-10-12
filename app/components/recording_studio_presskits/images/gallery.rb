# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    module Gallery
      def gallery_images_for(recording)
        DirectImages.list(recording)
      end

      def gallery_image_url(item)
        DirectImages.url_for(item, helpers: helpers)
      end

      def gallery_image_alt(item)
        DirectImages.alt_for(item)
      end
    end
  end
end
