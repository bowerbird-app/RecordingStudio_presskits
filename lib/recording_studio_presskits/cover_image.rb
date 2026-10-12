# frozen_string_literal: true

module RecordingStudioPresskits
  class CoverImage
    class << self
      def resolved(recording)
        DirectImages.list(recording).first
      end

      def url_for(recording, helpers:)
        DirectImages.url_for(resolved(recording), helpers: helpers)
      end

      def alt_for(recording)
        DirectImages.alt_for(resolved(recording), fallback: "Cover")
      end

      def enabled?(recording)
        DirectImages.enabled?(recording)
      end
    end
  end
end
