# frozen_string_literal: true

require "test_helper"

class ImagePixelSizeTest < Minitest::Test
  def test_reads_jpeg_pixel_size
    width, height = File.open(cover_path, "rb") { |io| RecordingStudioPresskits::ImagePixelSize.read(io) }

    assert_equal [64, 28], [width, height]
  end

  def test_reads_png_pixel_size
    png = +"\x89PNG\r\n\x1A\n".b
    png << [13].pack("N")
    png << "IHDR"
    png << [320, 200, 8, 2, 0, 0, 0].pack("N2C5")
    png << "crc!"

    assert_equal [320, 200], RecordingStudioPresskits::ImagePixelSize.read(StringIO.new(png))
  end

  def test_ignores_a_file_that_is_not_an_image
    assert_nil RecordingStudioPresskits::ImagePixelSize.read(StringIO.new("not an image, really"))
  end

  private

  def cover_path
    File.expand_path("fixtures/files/cover.jpg", __dir__)
  end
end
