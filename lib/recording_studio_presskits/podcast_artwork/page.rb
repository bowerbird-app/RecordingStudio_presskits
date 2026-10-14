# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastArtwork
    # Open Graph and Twitter card tags from a small slice of HTML.
    class Page
      def self.image(html)
        content(html, "og:image") || content(html, "twitter:image")
      end

      def self.title(html)
        content(html, "og:title").to_s.strip.presence
      end

      def self.content(html, name)
        tag = html.to_s.scan(/<meta\b[^>]*>/i).find { |item| meta_name(item) == name }
        return if tag.blank?

        tag[/content=["']([^"']+)["']/i, 1]
      end

      def self.meta_name(tag)
        tag[/property=["']([^"']+)["']/i, 1] || tag[/name=["']([^"']+)["']/i, 1]
      end
      private_class_method :content, :meta_name
    end
  end
end
