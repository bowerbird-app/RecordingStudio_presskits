# frozen_string_literal: true

require "json"
require "uri"
require "recording_studio_presskits/podcast_artwork/page"

module RecordingStudioPresskits
  class PodcastArtwork
    # Turns a page URL into image bytes. A passed-in client skips the network
    # and the private-address check, so tests stay offline.
    class Remote
      HTML_LIMIT = 200_000
      IMAGE_LIMIT = 5_000_000
      IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

      def self.image_for(page_url, http: nil)
        new(http).image_for(page_url)
      end

      def initialize(http)
        @http = http
      end

      def image_for(page_url)
        page = https_uri(page_url)
        return unless page

        meta = spotify?(page) ? spotify_meta(page) : page_meta(page)
        download(meta)
      rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error, SocketError
        nil
      end

      private

      def download(meta)
        return if meta.blank? || meta[:image].blank?

        status, body, type = read(https_uri(meta[:image]), IMAGE_LIMIT)
        return unless status == 200 && image_type?(type) && body.present?

        Image.new(
          bytes: body,
          content_type: type,
          filename: filename_for(type),
          title: meta[:title],
          show_name: meta[:show_name]
        )
      end

      def spotify_meta(page)
        status, body, = read(oembed_uri(page), HTML_LIMIT)
        return unless status == 200

        data = JSON.parse(body.to_s)
        return unless data.is_a?(Hash)

        {
          image: data["thumbnail_url"].to_s,
          title: data["title"].to_s.strip.presence,
          show_name: data["author_name"].to_s.strip.presence
        }
      end

      def page_meta(page)
        status, body, type = read(page, HTML_LIMIT)
        return unless status == 200 && type.to_s.start_with?("text/html")

        {
          image: Page.image(body),
          title: Page.title(body),
          show_name: nil
        }
      end

      def read(uri, limit, hops: 1)
        return empty unless uri

        response = @http.call(uri)
        return empty unless response

        slice(response, limit, hops)
      end

      def slice(response, limit, hops)
        status, body, type, location = response
        status = status.to_i
        return read(https_uri(location), limit, hops: hops - 1) if follow?(status, location, hops)

        [status, body.to_s.byteslice(0, limit), media_type(type)]
      end

      def follow?(status, location, hops)
        redirect?(status) && location.present? && hops.positive?
      end

      def empty
        [0, "", ""]
      end

      def media_type(type)
        type.to_s.split(";").first.to_s.strip.downcase
      end

      def redirect?(status)
        [301, 302, 303, 307, 308].include?(status)
      end

      def oembed_uri(page)
        query = URI.encode_www_form_component(page.to_s)
        https_uri("https://open.spotify.com/oembed?url=#{query}")
      end

      def spotify?(page)
        host = page.host.to_s.downcase.delete_prefix("www.")
        %w[open.spotify.com spotify.com].include?(host)
      end

      def https_uri(value)
        uri = URI.parse(value.to_s.strip)
        return unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?

        uri
      rescue URI::InvalidURIError
        nil
      end

      def image_type?(type)
        IMAGE_TYPES.include?(type)
      end

      def filename_for(type)
        extension = { "image/jpeg" => "jpg", "image/png" => "png", "image/webp" => "webp", "image/gif" => "gif" }
        "cover.#{extension.fetch(type, 'img')}"
      end
    end
  end
end
