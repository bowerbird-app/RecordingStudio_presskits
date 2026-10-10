# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover_image"

class CoverImageTest < Minitest::Test
  def test_resolved_is_blank_without_a_recording
    assert_nil RecordingStudioPresskits::CoverImage.resolved(nil)
    assert_nil RecordingStudioPresskits::CoverImage.resolved(Object.new)
  end

  def test_alt_falls_back_to_cover
    recording = Object.new
    def recording.library_placements
      []
    end

    assert_equal "Cover", RecordingStudioPresskits::CoverImage.alt_for(recording)
  end

  def test_enabled_is_false_without_a_recording
    assert_equal false, RecordingStudioPresskits::CoverImage.enabled?(nil)
  end
end
