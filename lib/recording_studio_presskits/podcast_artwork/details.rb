# frozen_string_literal: true

require "json"
require "uri"
require "recording_studio_presskits/podcast_artwork/page"

module RecordingStudioPresskits
  class PodcastArtwork
    # Title, show, and image URL from Spotify oEmbed or an Open Graph page.
    class Details
      def self.for(page, reader)
        new(page, reader).to_h
      end

      def initialize(page, reader)
        @page = page
        @reader = reader
      end

      def to_h
        spotify? ? spotify_meta : page_meta
      end

      private

      def spotify_meta
        status, body, = read(oembed_uri, Remote::HTML_LIMIT)
        return unless status == 200

        data = JSON.parse(body.to_s)
        return unless data.is_a?(Hash)

        oembed_meta(data)
      end

      def oembed_meta(data)
        meta = {
          image: data["thumbnail_url"].to_s,
          title: data["title"].to_s.strip.presence,
          show_name: data["author_name"].to_s.strip.presence
        }
        meta[:show_name] ||= show_from
        meta
      end

      def show_from
        status, body, type = read(@page, Remote::HTML_LIMIT)
        return unless status == 200 && html?(type)

        Page.show_name(body)
      end

      def page_meta
        status, body, type = read(@page, Remote::HTML_LIMIT)
        return unless status == 200 && html?(type)

        {
          image: Page.image(body),
          title: Page.title(body),
          show_name: Page.show_name(body)
        }
      end

      def read(uri, limit)
        @reader.call(uri, limit)
      end

      def html?(type)
        type.to_s.start_with?("text/html")
      end

      def oembed_uri
        query = URI.encode_www_form_component(@page.to_s)
        URI.parse("https://open.spotify.com/oembed?url=#{query}")
      end

      def spotify?
        host = @page.host.to_s.downcase.delete_prefix("www.")
        %w[open.spotify.com spotify.com].include?(host)
      end
    end
  end
end
