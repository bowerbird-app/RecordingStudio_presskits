# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module RecordingStudioPresskits
  # A poster when the editor left the thumbnail blank.
  # YouTube has a public image URL. Vimeo does not, so we ask its oEmbed endpoint.
  module VideoPoster
    YOUTUBE_ID = /[A-Za-z0-9_-]{11}/
    VIMEO_ID = /\A\d{1,12}\z/
    CACHE_TTL = 12.hours

    def self.url_for(page_url, http: nil)
      youtube = youtube_id(page_url)
      return "https://i.ytimg.com/vi/#{youtube}/hqdefault.jpg" if youtube

      vimeo = vimeo_id(page_url)
      return vimeo_thumbnail(vimeo, http: http) if vimeo

      nil
    end

    def self.youtube_id(page_url)
      uri = parse_https(page_url)
      return unless uri

      host = uri.host.to_s.downcase.delete_prefix("www.")
      from_youtube(uri, host) || from_short_link(uri, host)
    end

    def self.vimeo_id(page_url)
      uri = parse_https(page_url)
      return unless uri

      host = uri.host.to_s.downcase.delete_prefix("www.")
      return unless %w[vimeo.com player.vimeo.com].include?(host)

      match = uri.path.match(%r{\A/(?:video/)?(\d{1,12})/?\z})
      match[1] if match && match[1].match?(VIMEO_ID)
    end

    def self.vimeo_thumbnail(id, http:)
      return fetch_vimeo(id, http: http) if http
      return fetch_vimeo(id, http: live_http) unless cache?

      Rails.cache.fetch(cache_key(id), expires_in: CACHE_TTL, skip_nil: true) do
        fetch_vimeo(id, http: live_http)
      end
    end

    def self.fetch_vimeo(id, http:)
      uri = URI("https://vimeo.com/api/oembed.json?url=#{URI.encode_www_form_component("https://vimeo.com/#{id}")}")
      status, body = http.call(uri)
      return unless status.to_i == 200

      data = JSON.parse(body.to_s)
      thumbnail = data.is_a?(Hash) ? data["thumbnail_url"].to_s : ""
      thumbnail if trusted_https?(thumbnail)
    rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error, SocketError
      nil
    end

    def self.live_http
      lambda do |uri|
        client = Net::HTTP.new(uri.host, uri.port)
        client.use_ssl = true
        client.open_timeout = 1
        client.read_timeout = 2
        response = client.request(Net::HTTP::Get.new(uri))
        [response.code.to_i, response.body.to_s]
      end
    end

    def self.from_youtube(uri, host)
      return unless %w[youtube.com m.youtube.com].include?(host)

      if uri.path.match?(%r{\A/watch/?\z})
        id = query_value(uri, "v")
        return id if id&.match?(/\A#{YOUTUBE_ID.source}\z/)
      end

      match = uri.path.match(%r{\A/(?:embed|shorts)/(#{YOUTUBE_ID.source})/?\z})
      match && match[1]
    end

    def self.from_short_link(uri, host)
      return unless host == "youtu.be"

      match = uri.path.match(%r{\A/(#{YOUTUBE_ID.source})/?\z})
      match && match[1]
    end

    def self.query_value(uri, key)
      URI.decode_www_form(uri.query.to_s).to_h[key]
    rescue ArgumentError
      nil
    end

    def self.parse_https(page_url)
      uri = URI.parse(page_url.to_s.strip)
      uri if uri.is_a?(URI::HTTPS) && uri.host
    rescue URI::InvalidURIError
      nil
    end

    def self.trusted_https?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
    rescue URI::InvalidURIError
      false
    end

    def self.cache?
      defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache
    end

    def self.cache_key(id)
      "recording_studio_presskits/vimeo-poster/#{id}"
    end

    private_class_method :vimeo_thumbnail, :fetch_vimeo, :live_http, :from_youtube, :from_short_link,
                         :query_value, :parse_https, :trusted_https?, :cache?, :cache_key
  end
end
