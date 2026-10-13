# frozen_string_literal: true

require "test_helper"

class CenterBrandingTest < Minitest::Test
  BRANDED_STYLE = "--color-primary: #0F766E; font-family: Georgia, serif"

  def teardown
    remove_press_centers
  end

  def test_branding_style_returns_the_press_center_style_string
    kit = Object.new
    install_press_centers(BRANDED_STYLE)

    assert_equal BRANDED_STYLE, RecordingStudioPresskits.branding_style_for(kit)
    assert_same kit, RecordingStudioPressCenters.kit_recording
  end

  def test_nil_branding_leaves_the_style_blank
    install_press_centers(nil)

    assert_nil RecordingStudioPresskits.branding_style_for(Object.new)
  end

  def test_missing_press_centers_leaves_the_style_blank
    remove_press_centers

    assert_nil RecordingStudioPresskits.branding_style_for(Object.new)
    refute defined?(RecordingStudioPressCenters)
  end

  def test_presskits_does_not_depend_on_press_centers
    root = File.expand_path("..", __dir__)
    gemspec = File.read(File.join(root, "recording_studio_presskits.gemspec"))
    gemfile = File.read(File.join(root, "Gemfile"))
    dummy_gemfile = File.read(File.join(root, "test/dummy/Gemfile"))

    refute_includes gemspec, "press_center"
    refute_includes gemfile, "press_center"
    refute_includes dummy_gemfile, "press_center"
    source = File.read(File.join(root, "lib/recording_studio_presskits/center_branding.rb"))
    assert_includes source, "defined?(RecordingStudioPressCenters)"
    assert_includes source, "RecordingStudioPressCenters.branding_for(kit_recording)&.style_attribute"
  end

  private

  def install_press_centers(style)
    remove_press_centers
    mod = Module.new
    mod.define_singleton_method(:branding_for) do |kit_recording|
      mod.instance_variable_set(:@kit_recording, kit_recording)
      return if style.nil?

      Struct.new(:style_attribute).new(style)
    end
    mod.define_singleton_method(:kit_recording) { instance_variable_get(:@kit_recording) }
    Object.const_set(:RecordingStudioPressCenters, mod)
  end

  def remove_press_centers
    return unless defined?(RecordingStudioPressCenters)

    Object.send(:remove_const, :RecordingStudioPressCenters)
  end
end
