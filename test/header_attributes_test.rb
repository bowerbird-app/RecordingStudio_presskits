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
    assert_nil fields[:text_color]
    assert_nil fields[:corner_style]
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
    assert_nil fields[:text_color]
    assert_nil fields[:corner_style]
  end

  def test_custom_stores_button_text_and_corners_with_the_swatches
    fields = RecordingStudioPresskits::HeaderAttributes.from(
      brand_source: "custom",
      brand_color: "#333333",
      font_family: "sans",
      text_color: "#F8FAFC",
      corner_style: "square"
    )

    assert_equal "#F8FAFC", fields[:text_color]
    assert_equal "square", fields[:corner_style]
  end

  def test_a_title_only_save_does_not_touch_brand_fields
    fields = RecordingStudioPresskits::HeaderAttributes.from(title: "Spring", subtitle: "   ")

    assert_nil fields[:subtitle]
    refute fields.key?(:description)
    refute fields.key?(:brand_color)
    refute fields.key?(:font_family)
    refute fields.key?(:brand_source)
    refute fields.key?(:release_date)
  end

  def test_release_date_parses_an_iso_date_and_a_blank_clears_it
    fields = RecordingStudioPresskits::HeaderAttributes.from(release_date: "2026-10-14")

    assert_equal Date.new(2026, 10, 14), fields[:release_date]

    cleared = RecordingStudioPresskits::HeaderAttributes.from(release_date: "  ")
    assert_nil cleared[:release_date]

    invalid = RecordingStudioPresskits::HeaderAttributes.from(release_date: "not-a-date")
    assert_nil invalid[:release_date]
  end

  def test_omitted_copy_stays_out_of_the_header_write
    fields = RecordingStudioPresskits::HeaderAttributes.from(title: " Spring ")

    assert_equal({ title: "Spring" }, fields)
  end
end
