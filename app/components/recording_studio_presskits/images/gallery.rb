# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    module Gallery
      def gallery_images_for(recording)
        LibraryImages.resolve(recording)
      end

      def gallery_image_url(item)
        LibraryImages.url_for(item, helpers: helpers)
      end

      def gallery_image_alt(item)
        LibraryImages.alt_for(item)
      end
    end
  end
end
