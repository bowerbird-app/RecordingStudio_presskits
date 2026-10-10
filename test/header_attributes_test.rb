# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/header_attributes"

class HeaderAttributesTest < Minitest::Test
  def test_from_strips_title_and_blank_description
    fields = RecordingStudioPresskits::HeaderAttributes.from(
      title: " Spring launch ",
      description: "  ",
      cover_style: "color",
      cover_color: "#BFDBFE"
    )

    assert_equal "Spring launch", fields[:title]
    assert_nil fields[:description]
    assert_equal "color", fields[:cover_style]
    assert_equal "#BFDBFE", fields[:cover_color]
  end

  def test_auto_text_colour_is_nil
    assert_nil RecordingStudioPresskits::HeaderAttributes.text_color(cover_text_color: "auto")
  end

  def test_blank_choice_uses_the_swatch
    hex = RecordingStudioPresskits::HeaderAttributes.text_color(
      cover_text_color: "",
      cover_text_swatch: "#111827"
    )

    assert_equal "#111827", hex
  end
end
