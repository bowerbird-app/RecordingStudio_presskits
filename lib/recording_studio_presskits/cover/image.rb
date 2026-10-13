# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    module Image
      def cover_image?
        cover_image_url.present?
      end

      def cover_image_url
        return if preview? || !show_cover_image?

        CoverImage.url_for(@recording, helpers: helpers)
      end

      def show_cover_image?
        return true unless instance_variable_defined?(:@show_image)

        @show_image != false
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
