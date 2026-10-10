# frozen_string_literal: true

module RecordingStudioPresskits
  class CoverImage
    class << self
      def resolved(recording)
        LibraryImages.resolve(recording).first
      end

      def url_for(recording, helpers:)
        LibraryImages.url_for(resolved(recording), helpers: helpers)
      end

      def alt_for(recording)
        LibraryImages.alt_for(resolved(recording), fallback: "Cover")
      end

      def enabled?(recording)
        LibraryImages.enabled?(recording)
      end
    end
  end
end
