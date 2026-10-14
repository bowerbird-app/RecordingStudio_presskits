# frozen_string_literal: true

require "test_helper"
require "base64"
require "json"

class PodcastEmbedTest < Minitest::Test
  SPOTIFY = "https://open.spotify.com/episode/4iV5W9uYEdYUVa79Axb7Rh"
  APPLE = "https://podcasts.apple.com/us/podcast/example/id123?i=100"
  PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  )

  def test_spotify_and_apple_links_name_a_service_and_an_embed
    spotify = RecordingStudioPresskits::PodcastEmbed.for(SPOTIFY)
    apple = RecordingStudioPresskits::PodcastEmbed.for("#{APPLE}&uo=4")
    site = RecordingStudioPresskits::PodcastEmbed.for("https://www.example.com/show")

    assert_equal "Spotify", spotify.service
    assert_equal "https://open.spotify.com/embed/episode/4iV5W9uYEdYUVa79Axb7Rh", spotify.embed_url
    assert_equal "Apple Podcasts", apple.service
    assert_equal "https://embed.podcasts.apple.com/us/podcast/example/id123?i=100&uo=4", apple.embed_url
    assert_equal "example.com", site.service
    assert_nil site.embed_url
  end

  def test_a_spotify_show_link_embeds_the_show
    embed = RecordingStudioPresskits::PodcastEmbed.for("https://open.spotify.com/show/abc123")

    assert_equal "https://open.spotify.com/embed/show/abc123", embed.embed_url
  end

  def test_remote_artwork_uses_spotify_oembed_without_hotlinking
    image = RecordingStudioPresskits::PodcastArtwork::Remote.image_for(SPOTIFY, http: spotify_http)

    assert_equal PNG, image.bytes
    assert_equal "image/png", image.content_type
    assert_equal "Fetched title", image.title
    assert_equal "Fetched show", image.show_name
  end

  def test_remote_artwork_reads_open_graph_when_the_page_is_not_spotify
    html = '<meta property="og:title" content="Office hours"><meta property="og:image" content="https://cdn.example.com/cover.png">'
    http = lambda do |uri|
      if uri.host == "shows.example.com"
        [200, html, "text/html; charset=utf-8", nil]
      else
        [200, PNG, "image/png", nil]
      end
    end

    image = RecordingStudioPresskits::PodcastArtwork::Remote.image_for("https://shows.example.com/ep", http: http)

    assert_equal "Office hours", image.title
    assert_equal PNG, image.bytes
  end

  def test_remote_artwork_skips_http_userinfo_and_a_failed_oembed_without_a_download
    calls = 0
    http = lambda do |_uri|
      calls += 1
      [500, "", "text/html", nil]
    end

    remote = RecordingStudioPresskits::PodcastArtwork::Remote
    assert_nil remote.image_for("http://open.spotify.com/episode/abc", http: http)
    assert_nil remote.image_for("https://user:pass@open.spotify.com/episode/abc", http: http)
    assert_equal 0, calls

    assert_nil RecordingStudioPresskits::PodcastArtwork::Remote.image_for(SPOTIFY, http: http)
    assert_equal 1, calls
  end

  private

  def spotify_http
    lambda do |uri|
      if uri.path == "/oembed"
        body = {
          thumbnail_url: "https://i.scdn.co/image/abc.png",
          title: "Fetched title",
          author_name: "Fetched show"
        }.to_json
        [200, body, "application/json", nil]
      else
        [200, PNG, "image/png", nil]
      end
    end
  end
end
