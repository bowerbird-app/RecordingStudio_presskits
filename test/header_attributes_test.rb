# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/header_attributes"

class HeaderAttributesTest < Minitest::Test
  def test_from_strips_title_and_keeps_an_explicit_brand
    fields = RecordingStudioPresskits::HeaderAttributes.from(
      title: " Spring launch ",
      subtitle: "  Collection released  ",
      description: "  ",
      brand_source: "custom",
      brand_color: "#333333",
      font_family: "sans"
    )

    assert_equal "Spring launch", fields[:title]
    assert_equal "Collection released", fields[:subtitle]
    assert_nil fields[:description]
    assert_equal "#333333", fields[:brand_color]
    assert_equal "sans", fields[:font_family]
    assert_equal "custom", fields[:brand_source]
  end

  def test_press_center_stores_nil_for_both_fields
    fields = RecordingStudioPresskits::HeaderAttributes.from(
      title: "Spring",
      brand_source: "press_center",
      brand_color: "#0F766E",
      font_family: "serif"
    )

    assert_nil fields[:brand_color]
    assert_nil fields[:font_family]
    assert_equal "press_center", fields[:brand_source]
  end

  def test_custom_stores_both_swatch_values
    fields = RecordingStudioPresskits::HeaderAttributes.from(
      title: "Spring",
      brand_source: "custom",
      brand_color: "#333333",
      font_family: "sans"
    )

    assert_equal "#333333", fields[:brand_color]
    assert_equal "sans", fields[:font_family]
  end

  def test_a_title_only_save_does_not_touch_brand_fields
    fields = RecordingStudioPresskits::HeaderAttributes.from(title: "Spring", subtitle: "   ")

    assert_nil fields[:subtitle]
    refute fields.key?(:brand_color)
    refute fields.key?(:font_family)
    refute fields.key?(:brand_source)
  end
end
