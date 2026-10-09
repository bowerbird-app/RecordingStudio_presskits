# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover/hex"

class CoverHexTest < Minitest::Test
  def test_normalizes_hashless_and_short_hex
    assert_equal "#1F2937", RecordingStudioPresskits::Cover::Hex.normalize("#1f2937")
    assert_equal "#1F2937", RecordingStudioPresskits::Cover::Hex.normalize("1F2937")
    assert_equal "#112233", RecordingStudioPresskits::Cover::Hex.normalize("#123")
    assert_nil RecordingStudioPresskits::Cover::Hex.normalize("  ")
    assert_nil RecordingStudioPresskits::Cover::Hex.normalize("blue")
    assert_nil RecordingStudioPresskits::Cover::Hex.normalize("#12")
  end

  def test_valid_and_rgb
    assert RecordingStudioPresskits::Cover::Hex.valid?("#0f0")
    refute RecordingStudioPresskits::Cover::Hex.valid?("nope")
    assert_equal [31, 41, 55], RecordingStudioPresskits::Cover::Hex.rgb("#1F2937")
    assert_nil RecordingStudioPresskits::Cover::Hex.rgb("red")
  end
end
