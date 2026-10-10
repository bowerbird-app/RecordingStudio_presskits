# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    module Image
      def cover_image?
        cover_image_url.present?
      end

      def cover_image_url
        return if preview?

        CoverImage.url_for(@recording, helpers: helpers)
      end

      def cover_image_alt
        CoverImage.alt_for(@recording)
      end

      def image_frame_classes
        # Tailwind scans these literals: "aspect-[1440/640]"
        "w-full overflow-hidden aspect-[1440/640]"
      end

      def image_card?
        card? && cover_image?
      end
    end
  end
end
