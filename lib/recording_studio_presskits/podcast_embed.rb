# frozen_string_literal: true

require "uri"

module RecordingStudioPresskits
  class PodcastEmbed
    SPOTIFY_HOSTS = %w[open.spotify.com spotify.com].freeze
    EPISODE = %r{\A/(?:embed/)?episode/([A-Za-z0-9]+)(?:/|\z)}
    SHOW = %r{\A/(?:embed/)?show/([A-Za-z0-9]+)(?:/|\z)}

    def self.for(url)
      new(url)
    end

    def initialize(url)
      @uri = parse(url)
    end

    def service
      return if host.blank?

      case host
      when *SPOTIFY_HOSTS then "Spotify"
      when "podcasts.apple.com" then "Apple Podcasts"
      else host
      end
    end

    def embed_url
      spotify_embed || apple_embed
    end

    private

    def parse(url)
      uri = URI.parse(url.to_s.strip)
      return unless uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil?

      uri
    rescue URI::InvalidURIError
      nil
    end

    def host
      @uri&.host.to_s.downcase.delete_prefix("www.")
    end

    def spotify_embed
      return unless SPOTIFY_HOSTS.include?(host)

      id = episode_id || show_id
      return if id.blank?

      kind = episode_id ? "episode" : "show"
      "https://open.spotify.com/embed/#{kind}/#{id}"
    end

    def episode_id
      match = path.match(EPISODE)
      match && match[1]
    end

    def show_id
      match = path.match(SHOW)
      match && match[1]
    end

    def apple_embed
      return unless host == "podcasts.apple.com"
      return if @uri.path.blank? || @uri.path == "/"

      "https://embed.podcasts.apple.com#{@uri.path}#{query}"
    end

    def path
      @uri&.path.to_s
    end

    def query
      @uri.query.present? ? "?#{@uri.query}" : ""
    end
  end
end
