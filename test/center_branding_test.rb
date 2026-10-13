# frozen_string_literal: true

require "test_helper"

class CenterBrandingTest < Minitest::Test
  def teardown
    remove_press_centers
  end

  def test_branding_style_uses_resolved_fields
    kit = Struct.new(:recordable).new(Struct.new(:brand_color, :font_family).new(nil, nil))
    install_center

    assert_equal "color=#0F766E; font=serif", RecordingStudioPresskits.branding_style_for(kit)
  end

  def test_missing_press_centers_still_paints_the_defaults
    remove_press_centers
    kit = Struct.new(:recordable).new(Struct.new(:brand_color, :font_family).new(nil, nil))
    style = RecordingStudioPresskits.branding_style_for(kit)

    assert_includes style, "--color-primary: #333333"
    assert_includes style, "font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif"
    refute defined?(RecordingStudioPressCenters)
  end

  private

  def install_center
    remove_press_centers
    center = Struct.new(:brand_color, :font_family).new("#0F766E", "serif")
    mod = Module.new
    mod.define_singleton_method(:branding_for) { |_recording| center }
    spy = Class.new do
      def initialize(brand_color:, font_family:)
        @brand_color = brand_color
        @font_family = font_family
      end

      def style_attribute
        "color=#{@brand_color}; font=#{@font_family}"
      end
    end
    mod.const_set(:Branding, spy)
    Object.const_set(:RecordingStudioPressCenters, mod)
  end

  def remove_press_centers
    return unless defined?(RecordingStudioPressCenters)

    Object.send(:remove_const, :RecordingStudioPressCenters)
  end
end
