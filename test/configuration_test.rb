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
    assert_equal({}, configuration.section_components)
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
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

  def test_section_components_can_be_registered
    RecordingStudioPresskits.register_section_component("FakeBlock", "FakeBlock::Component")

    assert_equal "FakeBlock::Component", RecordingStudioPresskits.configuration.section_components["FakeBlock"]
  ensure
    RecordingStudioPresskits.configuration.section_components.delete("FakeBlock")
  end
end
