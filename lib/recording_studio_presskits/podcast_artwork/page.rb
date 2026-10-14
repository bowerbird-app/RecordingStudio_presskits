# frozen_string_literal: true

require "cgi"

module RecordingStudioPresskits
  class PodcastArtwork
    # Open Graph and Twitter card tags from a small slice of HTML.
    class Page
      PLATFORMS = ["spotify", "apple podcasts", "pocket casts", "youtube"].freeze

      def self.image(html)
        content(html, "og:image") || content(html, "twitter:image")
      end

      def self.title(html)
        tidy(content(html, "og:title")).presence
      end

      def self.show_name(html)
        text = html.to_s
        described(content(text, "og:description")) ||
          podcast_heading(text) ||
          document_title(text) ||
          usable(content(text, "og:site_name"))
      end

      def self.content(html, name)
        tag = html.to_s.scan(/<meta\b[^>]*>/i).find { |item| meta_name(item) == name }
        return if tag.blank?

        tag[/content=["']([^"']+)["']/i, 1]
      end

      def self.described(value)
        parts = pieces(value)
        return usable(parts[1]) if parts.first.to_s.casecmp("podcast episode").zero?
        return usable(parts.first) if parts.last.to_s.casecmp("episode").zero?

        nil
      end

      def self.podcast_heading(html)
        name = html[%r{<a\b[^>]*data-testid=["']podcast-title["'][^>]*>([^<]+)</a>}i, 1]
        usable(name)
      end

      def self.document_title(html)
        title = tidy(html[%r{<title>(.*?)</title>}im, 1])
        title = title.sub(/\s+\|\s+Podcast on Spotify\z/i, "")
        title = title.sub(/\s+-\s+Apple Podcasts\z/i, "")
        parts = title.split(/\s+-\s+/)
        return if parts.length < 2

        usable(parts.last)
      end

      def self.usable(value)
        name = tidy(value)
        return if name.blank? || PLATFORMS.include?(name.downcase)

        name
      end

      def self.pieces(value)
        tidy(value).split("·").map(&:strip).reject(&:blank?)
      end

      def self.tidy(value)
        CGI.unescapeHTML(utf8(value)).gsub(/\s+/, " ").strip
      end

      def self.utf8(value)
        text = value.to_s.dup
        text.force_encoding(Encoding::UTF_8)
        text.scrub
      end

      def self.meta_name(tag)
        tag[/property=["']([^"']+)["']/i, 1] || tag[/name=["']([^"']+)["']/i, 1]
      end
      private_class_method :content, :described, :podcast_heading, :document_title, :usable, :pieces, :tidy, :utf8,
                           :meta_name
    end
  end
end
