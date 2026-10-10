# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/section_images"
require "recording_studio_presskits/library_images"

class SectionImagesTest < Minitest::Test
  def test_place_requires_an_images_section
    result = RecordingStudioPresskits::SectionImages.place(
      images_recording: nil,
      attachment_recording: Object.new,
      actor: Object.new
    )

    assert result.failure?
    assert_equal "An images section is required.", result.error
  end

  def test_place_skips_a_photo_already_in_the_section
    RecordingStudioPresskits::LibraryImages.stub(:already_placed?, true) do
      result = RecordingStudioPresskits::SectionImages.place(
        images_recording: Object.new,
        attachment_recording: Object.new,
        actor: Object.new
      )

      assert result.failure?
      assert_equal "That photo is already in this section.", result.error
    end
  end

  def test_place_many_skips_every_duplicate
    RecordingStudioPresskits::LibraryImages.stub(:already_placed?, true) do
      result = RecordingStudioPresskits::SectionImages.place_many(
        images_recording: Object.new,
        attachment_recordings: [Object.new, Object.new],
        actor: Object.new
      )

      assert result.success?
      assert_equal 2, result.skipped
      assert_equal [], result.placed
    end
  end

  def test_remove_requires_an_images_section
    result = RecordingStudioPresskits::SectionImages.remove(
      images_recording: nil,
      placement_recording: Object.new,
      actor: Object.new
    )

    assert result.failure?
    assert_equal "An images section is required.", result.error
  end

  def test_write_requires_a_photo_or_file
    result = RecordingStudioPresskits::SectionImages.write(
      images_recording: Object.new,
      actor: Object.new,
      attachment_recordings: []
    )

    assert result.failure?
    assert_equal "Pick at least one photo.", result.error
  end

  def test_upload_requires_an_images_section
    result = RecordingStudioPresskits::SectionImages.upload_and_place(
      images_recording: nil,
      actor: Object.new,
      signed_blob_id: "blob"
    )

    assert result.failure?
    assert_equal "An images section is required.", result.error
  end
end
