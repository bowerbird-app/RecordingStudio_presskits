# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover/hex"
require "recording_studio_presskits/cover/palette"

class CoverPaletteTest < Minitest::Test
  def test_default_palette_and_names
    palette = RecordingStudioPresskits::Cover::Palette.new(
      colors: RecordingStudioPresskits::Cover::Palette::DEFAULT_COLORS,
      default_color: "#1F2937"
    )

    refute palette.any?
    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_COLORS, palette.colors
    assert_equal "#1F2937", palette.default_color
    assert palette.include?("#7c3aed")
    refute palette.include?("#FFFFFF")
    assert_equal "Violet", palette.label_for("#7C3AED")
    assert_equal "#ABCDEF", palette.label_for("#abcdef")
    assert_equal "Ink", palette.options.first[:label]
    assert_equal "#1F2937", palette.options.first[:value]
    auto = palette.options(auto: true)

    assert_equal "Auto", auto.first[:label]
    assert_equal RecordingStudioPresskits::Cover::Palette::AUTO_VALUE, auto.first[:value]
    assert palette.auto?("auto")
  end

  def test_text_palette_falls_back_to_the_text_defaults
    palette = RecordingStudioPresskits::Cover::Palette.new(
      colors: [],
      fallback_colors: RecordingStudioPresskits::Cover::Palette::DEFAULT_TEXT_COLORS
    )

    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_TEXT_COLORS, palette.colors
    assert_equal "Snow", palette.label_for("#F8FAFC")
    assert_equal "Slate", palette.label_for("#6B7280")
  end

  def test_any_mode_accepts_every_colour
    palette = RecordingStudioPresskits::Cover::Palette.new(colors: :any, default_color: "#111111")

    assert palette.any?
    assert_empty palette.colors
    assert palette.include?("#FFFFFF")
    assert_equal "#111111", palette.default_color
  end

  def test_blank_host_palette_falls_back_to_the_default_list
    palette = RecordingStudioPresskits::Cover::Palette.new(colors: [], default_color: "nope")

    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_COLORS, palette.colors
    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_COLOR, palette.default_color
  end
end
