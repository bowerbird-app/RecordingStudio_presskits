# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/library_images"

class LibraryImagesTest < Minitest::Test
  Resolved = Struct.new(:attachment_recording, :attachment, keyword_init: true)

  def test_resolve_is_empty_without_a_recording
    assert_equal [], RecordingStudioPresskits::LibraryImages.resolve(nil)
    assert_equal [], RecordingStudioPresskits::LibraryImages.resolve(Object.new)
  end

  def test_alt_falls_back_to_image
    assert_equal "Image", RecordingStudioPresskits::LibraryImages.alt_for(nil)
    assert_equal "Cover", RecordingStudioPresskits::LibraryImages.alt_for(nil, fallback: "Cover")
  end

  def test_alt_prefers_alt_text_then_name
    attachment = Struct.new(:alt_text, :name).new("Hall", "File")
    item = Resolved.new(attachment: attachment, attachment_recording: nil)

    assert_equal "Hall", RecordingStudioPresskits::LibraryImages.alt_for(item)

    attachment.alt_text = nil
    assert_equal "File", RecordingStudioPresskits::LibraryImages.alt_for(item)
  end

  def test_already_placed_is_false_without_recordings
    refute RecordingStudioPresskits::LibraryImages.already_placed?(nil, Object.new)
    refute RecordingStudioPresskits::LibraryImages.already_placed?(Object.new, nil)
  end

  def test_already_placed_matches_resolved_attachment_ids
    photo = Struct.new(:id).new(11)
    recording = Object.new
    def recording.library_placements
      []
    end

    RecordingStudioPresskits::LibraryImages.stub(:resolve, [Resolved.new(attachment_recording: photo)]) do
      assert RecordingStudioPresskits::LibraryImages.already_placed?(recording, photo)
      refute RecordingStudioPresskits::LibraryImages.already_placed?(recording, Struct.new(:id).new(99))
    end
  end

  def test_enabled_is_false_without_a_recording
    assert_equal false, RecordingStudioPresskits::LibraryImages.enabled?(nil)
  end
end
