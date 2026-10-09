# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover/hex"
require "recording_studio_presskits/cover/contrast"

class CoverContrastTest < Minitest::Test
  def test_picks_light_text_on_dark_ink
    assert_equal(
      RecordingStudioPresskits::Cover::Contrast::LIGHT,
      RecordingStudioPresskits::Cover::Contrast.text_on("#1F2937")
    )
  end

  def test_picks_dark_text_on_honey
    assert_equal(
      RecordingStudioPresskits::Cover::Contrast::DARK,
      RecordingStudioPresskits::Cover::Contrast.text_on("#D97706")
    )
  end

  def test_falls_back_when_the_background_is_blank
    assert_equal(
      RecordingStudioPresskits::Cover::Contrast::DARK,
      RecordingStudioPresskits::Cover::Contrast.text_on(nil)
    )
  end

  def test_light_text_has_the_better_contrast_on_ink
    ink = "#1F2937"
    light = RecordingStudioPresskits::Cover::Contrast.contrast(ink, RecordingStudioPresskits::Cover::Contrast::LIGHT)
    dark = RecordingStudioPresskits::Cover::Contrast.contrast(ink, RecordingStudioPresskits::Cover::Contrast::DARK)

    assert_operator light, :>, dark
    assert_operator light, :>=, 4.5
  end

  def test_low_contrast_detects_a_weak_pair
    refute RecordingStudioPresskits::Cover::Contrast.low_contrast?("#1F2937", "#F8FAFC")
    assert RecordingStudioPresskits::Cover::Contrast.low_contrast?("#D97706", "#E5E7EB")
  end
end
