# frozen_string_literal: true

require_relative "test_helper"

class VideoPosterTest < Minitest::Test
  def test_clock_parses_minutes_and_seconds
    assert_nil RecordingStudioPresskits::VideoClock.parse("  ")
    assert_equal 84, RecordingStudioPresskits::VideoClock.parse("1:24")
    assert_equal 84, RecordingStudioPresskits::VideoClock.parse("01:24")
    assert_equal 5400, RecordingStudioPresskits::VideoClock.parse("90:00")
    assert_equal :invalid, RecordingStudioPresskits::VideoClock.parse("1:99")
    assert_equal :invalid, RecordingStudioPresskits::VideoClock.parse("1:2")
    assert_equal "1:24", RecordingStudioPresskits::VideoClock.format(84)
    assert_equal "0:05", RecordingStudioPresskits::VideoClock.format(5)
  end

  def test_youtube_poster_uses_hqdefault
    url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
    assert_equal "jNQXAC9IVRw", RecordingStudioPresskits::VideoPoster.youtube_id(url)
    assert_equal(
      "https://i.ytimg.com/vi/jNQXAC9IVRw/hqdefault.jpg",
      RecordingStudioPresskits::VideoPoster.url_for(url)
    )
    assert_equal "dQw4w9WgXcQ", RecordingStudioPresskits::VideoPoster.youtube_id("https://youtu.be/dQw4w9WgXcQ")
  end

  def test_vimeo_poster_reads_oembed_thumbnail
    http = lambda do |uri|
      assert_includes uri.to_s, "https://vimeo.com/api/oembed.json"
      assert_includes uri.to_s, "76979871"
      [200, { thumbnail_url: "https://i.vimeocdn.com/video/poster.jpg" }.to_json]
    end

    assert_equal "76979871", RecordingStudioPresskits::VideoPoster.vimeo_id("https://vimeo.com/76979871")
    assert_equal(
      "https://i.vimeocdn.com/video/poster.jpg",
      RecordingStudioPresskits::VideoPoster.url_for("https://vimeo.com/76979871", http: http)
    )
  end

  def test_vimeo_poster_ignores_a_failed_oembed
    http = ->(_uri) { [404, ""] }

    assert_nil RecordingStudioPresskits::VideoPoster.url_for("https://vimeo.com/76979871", http: http)
  end
end
