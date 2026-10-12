# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/direct_images"

class DirectImagesTest < Minitest::Test
  def test_list_is_empty_without_a_recording
    assert_equal [], RecordingStudioPresskits::DirectImages.list(nil)
    assert_equal [], RecordingStudioPresskits::DirectImages.list(Object.new)
  end

  def test_alt_falls_back_when_the_attachment_is_blank
    assert_equal "Image", RecordingStudioPresskits::DirectImages.alt_for(nil)
    assert_equal "Cover", RecordingStudioPresskits::DirectImages.alt_for(nil, fallback: "Cover")
  end

  def test_alt_prefers_alt_text_then_name
    attachment = Struct.new(:alt_text, :name).new("Hall", "File")
    item = Struct.new(:recordable).new(attachment)

    assert_equal "Hall", RecordingStudioPresskits::DirectImages.alt_for(item)

    attachment.alt_text = "  "
    assert_equal "File", RecordingStudioPresskits::DirectImages.alt_for(item)
  end

  def test_enabled_is_false_without_a_recording
    assert_equal false, RecordingStudioPresskits::DirectImages.enabled?(nil)
  end
end
