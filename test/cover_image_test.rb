# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover_image"
require "recording_studio_presskits/cover/image"

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

  def test_cover_image_helpers_live_on_the_image_module
    assert RecordingStudioPresskits::Cover::Image.method_defined?(:cover_image?)
    assert RecordingStudioPresskits::Cover::Image.method_defined?(:image_card?)
  end
end
