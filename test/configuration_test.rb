# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioPresskits::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(parent_root_type: "Site", authentication_method: :sign_in)

    assert_equal "Site", @configuration.parent_root_type
    assert_equal :sign_in, @configuration.authentication_method
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", parent_root_type: "Folder")

    refute_respond_to @configuration, :unknown_key
    assert_equal "Folder", @configuration.parent_root_type
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original[:parent_root_type], @configuration.parent_root_type
    assert_equal original[:authentication_method], @configuration.authentication_method
  end

  def test_initialize_uses_workspace_parent_and_host_auth_defaults
    configuration = RecordingStudioPresskits::Configuration.new

    assert_equal "Workspace", configuration.parent_root_type
    assert_equal :authenticate_user!, configuration.authentication_method
    assert_equal :current_user, configuration.current_actor_method
    assert_equal [], configuration.section_types
    assert_equal({}, configuration.section_components)
    assert_equal({}, configuration.section_editors)
    assert_equal({}, configuration.to_h.fetch(:section_editors))
    assert_equal [], configuration.excluded_picker_types
    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_COLORS, configuration.cover_palette.colors
    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_COLOR, configuration.cover_palette.default_color
    refute configuration.any_cover_color?
    assert_equal RecordingStudioPresskits::Cover::Palette::DEFAULT_TEXT_COLORS, configuration.cover_text_palette.colors
    refute configuration.any_cover_text_color?
    assert configuration.cover_text_auto?
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
  end

  def test_cover_colors_any_is_exported
    @configuration.merge!(cover_colors: :any, default_cover_color: "#112233")

    assert @configuration.any_cover_color?
    assert_equal :any, @configuration.to_h.fetch(:cover_colors)
    assert_equal "#112233", @configuration.to_h.fetch(:default_cover_color)
  end

  def test_cover_text_colors_any_and_auto_are_exported
    @configuration.merge!(cover_text_colors: :any, cover_text_auto: false)

    assert @configuration.any_cover_text_color?
    assert_equal :any, @configuration.to_h.fetch(:cover_text_colors)
    refute @configuration.to_h.fetch(:cover_text_auto)
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("parent_root_type" => "Organisation")

    assert_equal "Organisation", @configuration.parent_root_type
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioPresskits.configure

    assert_kind_of RecordingStudioPresskits::Configuration, RecordingStudioPresskits.configuration
  end

  def test_register_section_keeps_the_type_on_the_configuration
    RecordingStudioPresskits.register_section("PresskitsRegisteredSection", component: "PresskitsRegisteredSection::Component")

    assert_includes RecordingStudioPresskits.section_types, "PresskitsRegisteredSection"
    assert_equal "PresskitsRegisteredSection::Component",
                 RecordingStudioPresskits.configuration.section_components["PresskitsRegisteredSection"]
    assert_includes RecordingStudioPresskits.configuration.to_h.fetch(:section_types), "PresskitsRegisteredSection"
  ensure
    RecordingStudioPresskits.configuration.section_types.delete("PresskitsRegisteredSection")
    RecordingStudioPresskits.configuration.section_components.delete("PresskitsRegisteredSection")
  end

  def test_section_components_can_be_registered
    RecordingStudioPresskits.register_section_component("FakeBlock", "FakeBlock::Component")

    assert_equal "FakeBlock::Component", RecordingStudioPresskits.configuration.section_components["FakeBlock"]
  ensure
    RecordingStudioPresskits.configuration.section_components.delete("FakeBlock")
  end

  def test_section_editors_register_string_and_class_and_miss_returns_nil
    assert_equal({}, RecordingStudioPresskits.configuration.section_editors)

    editor_class = Class.new
    Object.const_set(:PresskitsStringEditor, Class.new)
    Object.const_set(:MissingSection, Module.new)
    MissingSection.const_set(:Component, Class.new)
    MissingSection.const_set(:EditComponent, Class.new)
    RecordingStudioPresskits.register_section_editor("StringedSection", "PresskitsStringEditor")
    RecordingStudioPresskits.register_section_editor("ClassedSection", editor_class)

    assert_equal "PresskitsStringEditor", RecordingStudioPresskits.configuration.section_editors["StringedSection"]
    assert_equal editor_class, RecordingStudioPresskits.configuration.section_editors["ClassedSection"]
    assert_equal PresskitsStringEditor, RecordingStudioPresskits.section_editor_for("StringedSection")
    assert_equal editor_class, RecordingStudioPresskits.section_editor_for("ClassedSection")
    typed = Struct.new(:recordable_type).new("ClassedSection")
    assert_equal editor_class, RecordingStudioPresskits.section_editor_for(typed)
    assert_nil RecordingStudioPresskits.section_editor_for("MissingSection")
    assert_equal MissingSection::Component, RecordingStudioPresskits.section_component_for("MissingSection")

    exported = RecordingStudioPresskits.configuration.to_h.fetch(:section_editors)
    assert_equal "PresskitsStringEditor", exported.fetch("StringedSection")
    assert_equal editor_class, exported.fetch("ClassedSection")
    exported["Extra"] = "nope"
    refute RecordingStudioPresskits.configuration.section_editors.key?("Extra")
  ensure
    editors = RecordingStudioPresskits.configuration.section_editors
    editors.delete("StringedSection")
    editors.delete("ClassedSection")
    Object.send(:remove_const, :PresskitsStringEditor) if Object.const_defined?(:PresskitsStringEditor, false)
    Object.send(:remove_const, :MissingSection) if Object.const_defined?(:MissingSection, false)
  end
end
