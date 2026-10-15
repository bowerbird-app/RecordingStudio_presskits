# frozen_string_literal: true

require "test_helper"

class KitBrandingTest < Minitest::Test
  def teardown
    remove_press_centers
  end

  def test_nil_kit_uses_the_flatpack_defaults
    branding = RecordingStudioPresskits::KitBranding.for(kit(nil, nil))

    assert_equal "#333333", branding.brand_color
    assert_equal "sans", branding.font_family
    assert_default_style branding.style_attribute
  end

  def test_kit_values_win_over_the_press_center
    install_center(brand_color: "#0F766E", font_family: "serif")
    branding = RecordingStudioPresskits::KitBranding.for(kit("#DB2777", "mono"))

    assert_equal "#DB2777", branding.brand_color
    assert_equal "mono", branding.font_family
    assert_equal "color=#DB2777; font=mono", branding.style_attribute
  end

  def test_each_field_resolves_on_its_own
    install_center(brand_color: "#0F766E", font_family: "serif")
    branding = RecordingStudioPresskits::KitBranding.for(kit("#DB2777", nil))

    assert_equal "#DB2777", branding.brand_color
    assert_equal "serif", branding.font_family
    assert_equal "color=#DB2777; font=serif", branding.style_attribute
  end

  def test_a_blank_center_field_falls_through_to_the_default
    install_center(brand_color: nil, font_family: "mono")
    branding = RecordingStudioPresskits::KitBranding.for(kit(nil, nil))

    assert_equal "#333333", branding.brand_color
    assert_equal "mono", branding.font_family
  end

  def test_explicit_default_beats_a_branded_center
    install_center(brand_color: "#0F766E", font_family: "serif")
    branding = RecordingStudioPresskits::KitBranding.for(kit("#333333", "sans"))

    assert_equal "#333333", branding.brand_color
    assert_equal "sans", branding.font_family
    assert_equal "color=#333333; font=sans", branding.style_attribute
  end

  def test_missing_branding_class_uses_the_local_tokens
    install_center(brand_color: "#0F766E", font_family: "serif", painter: false)
    style = RecordingStudioPresskits.branding_style_for(kit(nil, nil))

    assert_includes style, "--color-primary: #0F766E"
    assert_includes style, "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast.text_on('#0F766E')}"
    assert_includes style, "--color-primary-hover: oklch(from var(--color-primary) calc(l - 0.1) c h)"
    assert_includes style, "--color-primary-active: oklch(from var(--color-primary) calc(l - 0.16) c h)"
    assert_includes style, "--button-primary-hover-background-color: var(--color-primary-hover)"
    assert_includes style, "--button-primary-active-background-color: var(--color-primary-active)"
    assert_includes style, "--button-focus-ring-color: var(--color-primary)"
    assert_includes style, "--button-primary-text-color: var(--color-primary-text)"
    assert_includes style, "font-family: ui-serif, Georgia, Cambria, Times New Roman, serif"
    refute defined?(RecordingStudioPressCenters::Branding)
  end

  def test_swatch_css_normalises_back_to_a_font_key
    sans = RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("sans")

    assert_equal "sans", RecordingStudioPresskits::BrandStyle.normalize_font(sans)
    assert_equal "serif", RecordingStudioPresskits::BrandStyle.normalize_font("Serif")
    assert_equal "#AABBCC", RecordingStudioPresskits::BrandStyle.normalize_color("#abc")
    assert_nil RecordingStudioPresskits::BrandStyle.normalize_color("")
    assert_equal :invalid, RecordingStudioPresskits::BrandStyle.normalize_color("blue")
    assert_equal :invalid, RecordingStudioPresskits::BrandStyle.normalize_font("comic")
  end

  def test_neutral_controls_restore_flatpack_primary_tokens
    style = RecordingStudioPresskits::BrandStyle.neutral_style_attribute

    assert_equal "presskits-neutral-controls", RecordingStudioPresskits::BrandStyle::NEUTRAL_CLASS
    assert_includes style, "--color-primary: oklch(var(--brand-lightness) var(--brand-chroma) var(--brand-hue))"
    assert_includes style, "--color-primary-text: #fff"
    assert_includes style, "--button-primary-background-color: var(--color-primary)"
    assert_includes style, "--button-focus-ring-color: var(--color-primary)"
    refute_includes style, "#0F766E"
    refute_includes style, "#FDE68A"
  end

  def test_a_light_brand_picks_dark_button_text
    style = RecordingStudioPresskits::BrandStyle.new(brand_color: "#FDE68A", font_family: "sans").style_attribute

    assert_includes style, "--color-primary: #FDE68A"
    assert_includes style, "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast::DARK}"
    assert_includes style, "--button-primary-text-color: var(--color-primary-text)"
  end

  def test_presskits_does_not_depend_on_press_centers
    root = File.expand_path("..", __dir__)
    gemspec = File.read(File.join(root, "recording_studio_presskits.gemspec"))
    gemfile = File.read(File.join(root, "Gemfile"))

    refute_includes gemspec, "press_center"
    refute_includes gemfile, "press_center"
    source = File.read(File.join(root, "lib/recording_studio_presskits/kit_branding.rb"))
    assert_includes source, "defined?(RecordingStudioPressCenters)"
    assert_includes source, "RecordingStudioPressCenters::Branding"
    assert_includes source, "own(:brand_color) || from_center(:brand_color)"
    assert_includes source, "own(:font_family) || from_center(:font_family)"
    assert_includes source, "own(:text_color) || from_center(:text_color)"
    assert_includes source, "own(:corner_style) || from_center(:corner_style)"
    assert_includes source, "text_color: text_color"
    assert_includes source, "corner_style: corner_style"
  end

  def test_text_colour_and_corners_pass_through_with_the_same_fallback
    install_center(brand_color: "#0F766E", font_family: "serif", text_color: "#F8FAFC", corner_style: "square")
    branding = RecordingStudioPresskits::KitBranding.for(kit(nil, nil))

    assert_equal "#F8FAFC", branding.text_color
    assert_equal "square", branding.corner_style
    assert_equal "color=#0F766E; font=serif; text=#F8FAFC; corners=square", branding.style_attribute
  end

  def test_a_kit_text_colour_and_corner_beat_the_center
    install_center(brand_color: "#0F766E", font_family: "serif", text_color: "#F8FAFC", corner_style: "square")
    branding = RecordingStudioPresskits::KitBranding.for(
      kit("#DB2777", nil, text_color: "#111827", corner_style: "rounded")
    )

    assert_equal "#111827", branding.text_color
    assert_equal "rounded", branding.corner_style
    assert_includes branding.style_attribute, "text=#111827"
    assert_includes branding.style_attribute, "corners=rounded"
    refute_includes branding.style_attribute, "corners=square"
  end

  def test_a_blank_text_colour_uses_auto_contrast_and_rounded_skips_square_radii
    style = RecordingStudioPresskits::BrandStyle.new(
      brand_color: "#FDE68A",
      font_family: "sans",
      text_color: nil,
      corner_style: "rounded"
    ).style_attribute

    assert_includes style, "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast::DARK}"
    refute_includes style, "--radius-lg: 0"
    refute_includes style, "--button-border-radius: 0"
  end

  def test_square_corners_zero_the_radius_tokens_and_an_explicit_text_colour_wins
    style = RecordingStudioPresskits::BrandStyle.new(
      brand_color: "#FDE68A",
      font_family: "sans",
      text_color: "#ffffff",
      corner_style: "square"
    ).style_attribute

    assert_includes style, "--color-primary-text: #FFFFFF"
    assert_includes style, "--radius-sm: 0"
    assert_includes style, "--radius-md: 0"
    assert_includes style, "--radius-lg: 0"
    assert_includes style, "--radius-xl: 0"
    assert_includes style, "--button-border-radius: 0"
    assert_equal "square", RecordingStudioPresskits::CornerStyle.normalize("Square")
    assert_nil RecordingStudioPresskits::CornerStyle.normalize(" ")
    assert_equal :invalid, RecordingStudioPresskits::CornerStyle.normalize("pill")
  end

  private

  def kit(brand_color, font_family, text_color: nil, corner_style: nil)
    recordable = Struct.new(:brand_color, :font_family, :text_color, :corner_style).new(
      brand_color, font_family, text_color, corner_style
    )
    Struct.new(:recordable).new(recordable)
  end

  def assert_default_style(style)
    assert_includes style, "--color-primary: #333333"
    assert_includes style, "font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif"
  end

  def install_center(brand_color:, font_family:, text_color: nil, corner_style: nil, painter: true)
    remove_press_centers
    center = Struct.new(:brand_color, :font_family, :text_color, :corner_style).new(
      brand_color, font_family, text_color, corner_style
    )
    mod = Module.new
    mod.define_singleton_method(:branding_for) { |_recording| center }
    if painter
      spy = Class.new do
        def initialize(brand_color:, font_family:, text_color: nil, corner_style: nil)
          @brand_color = brand_color
          @font_family = font_family
          @text_color = text_color
          @corner_style = corner_style
        end

        def style_attribute
          parts = ["color=#{@brand_color}", "font=#{@font_family}"]
          parts << "text=#{@text_color}" if @text_color
          parts << "corners=#{@corner_style}" if @corner_style
          parts.join("; ")
        end
      end
      mod.const_set(:Branding, spy)
    end
    Object.const_set(:RecordingStudioPressCenters, mod)
  end

  def remove_press_centers
    return unless defined?(RecordingStudioPressCenters)

    Object.send(:remove_const, :RecordingStudioPressCenters)
  end
end
