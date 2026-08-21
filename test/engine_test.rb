# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioPresskits.instance_variable_get(:@configuration)
    RecordingStudioPresskits.instance_variable_set(:@configuration, RecordingStudioPresskits::Configuration.new)
  end

  def teardown
    RecordingStudioPresskits.configuration.hooks.clear!
    RecordingStudioPresskits.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioPresskits.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioPresskits.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_presskits.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_presskits.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioPresskits.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_presskits).new({ current_actor_method: :current_person })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { parent_root_type: "Site", authentication_method: :sign_in }
      end
    end.new(app_config)

    find_initializer("recording_studio_presskits.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioPresskits.configuration, hook_payload
    assert_equal "Site", RecordingStudioPresskits.configuration.parent_root_type
    assert_equal :sign_in, RecordingStudioPresskits.configuration.authentication_method
    assert_equal :current_person, RecordingStudioPresskits.configuration.current_actor_method
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:parent_root_type, "Organisation")
      end
    end.new

    xcfg = Struct.new(:recording_studio_presskits).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)

    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(app_config)

    find_initializer("recording_studio_presskits.load_config").block.call(app)

    assert_equal "Organisation", RecordingStudioPresskits.configuration.parent_root_type
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_presskits).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { parent_root_type: "Site" }
      end
    end.new(app_config)

    # Should not raise even if xcfg.each_pair fails.
    find_initializer("recording_studio_presskits.load_config").block.call(app)

    assert_equal "Site", RecordingStudioPresskits.configuration.parent_root_type
  end

  def test_load_config_is_noop_without_config_sources
    app = Struct.new(:config).new(Object.new)

    find_initializer("recording_studio_presskits.load_config").block.call(app)

    assert_equal "Workspace", RecordingStudioPresskits.configuration.parent_root_type
    assert_equal :authenticate_user!, RecordingStudioPresskits.configuration.authentication_method
    assert_equal :current_user, RecordingStudioPresskits.configuration.current_actor_method
  end

  def test_load_config_ignores_non_enumerable_yaml_and_merge_errors
    yaml = Class.new do
      def each
        raise "bad yaml"
      end
    end.new

    xcfg = Struct.new(:recording_studio_presskits).new({ parent_root_type: "Account" })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      attr_accessor :yaml

      def config_for(_name)
        @yaml
      end
    end.new(app_config)
    app.yaml = yaml

    find_initializer("recording_studio_presskits.load_config").block.call(app)

    assert_equal "Account", RecordingStudioPresskits.configuration.parent_root_type
  end

  def test_apply_extension_initializers_register_active_support_on_load_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioPresskits::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_presskits.apply_model_extensions").block.call
      find_initializer("recording_studio_presskits.apply_controller_extensions").block.call
    end

    assert_equal 2, to_prepare_blocks.size
  end

  def test_helpers_initializer_registers_a_to_prepare_callback
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioPresskits::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_presskits.helpers").block.call
    end

    assert_equal 1, to_prepare_blocks.size
    to_prepare_blocks.first.call
  end

  def test_admin_initializer_registers_the_press_kits_section
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioPresskits::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_presskits.admin").block.call
    end

    registered = []
    RecordingStudioPresskits::Admin.stub(:register!, -> { registered << true }) do
      to_prepare_blocks.first.call
    end

    assert_equal [true], registered
  end

  def test_model_extension_initializer_skips_abstract_models
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    abstract_model = Class.new do
      def self.abstract_class?
        true
      end
    end
    concrete_model = Class.new do
      def self.abstract_class?
        false
      end
    end
    applied = []
    active_record_base = Class.new
    active_record_base.define_singleton_method(:descendants) { [abstract_model, concrete_model] }

    RecordingStudioPresskits::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_presskits.apply_model_extensions").block.call
    end

    with_temporary_nested_constant(:ActiveRecord, :Base, active_record_base) do
      RecordingStudioPresskits::Engine.stub(:apply_model_extensions, ->(model) { applied << model }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [concrete_model], applied
  end

  def test_controller_extension_initializer_applies_all_controllers
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    first_controller = Class.new
    second_controller = Class.new
    applied = []
    action_controller_base = Class.new
    action_controller_base.define_singleton_method(:descendants) { [first_controller, second_controller] }

    RecordingStudioPresskits::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_presskits.apply_controller_extensions").block.call
    end

    with_temporary_nested_constant(:ActionController, :Base, action_controller_base) do
      RecordingStudioPresskits::Engine.stub(:apply_controller_extensions, ->(controller) { applied << controller }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [first_controller, second_controller], applied
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioPresskits.configuration.hooks.extend_model(:ExampleRecord) do
      def template_extension_method
        :applied
      end
    end

    RecordingStudioPresskits::Engine.apply_model_extensions(model_class)
    RecordingStudioPresskits::Engine.apply_model_extensions(model_class)

    instance = model_class.new
    assert_equal :applied, instance.template_extension_method
  end

  def test_apply_controller_extensions_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::DashboardController"
      end
    end

    RecordingStudioPresskits.configuration.hooks.extend_controller(:DashboardController) do
      def template_controller_extension
        :applied
      end
    end

    RecordingStudioPresskits::Engine.apply_controller_extensions(controller_class)

    instance = controller_class.new
    assert_equal :applied, instance.template_controller_extension
  end

  def test_apply_extensions_flattens_compacts_and_tracks_identity
    target = Class.new
    extension = proc do
      def generated_method
        :generated
      end
    end

    RecordingStudioPresskits::Engine.send(:apply_extensions, target, [nil, [extension, extension]])

    assert_equal :generated, target.new.generated_method
    applied = target.instance_variable_get(:@recording_studio_presskits_applied_extensions)
    assert_equal true, applied.compare_by_identity?
  end

  def test_apply_extensions_returns_without_target
    assert_nil RecordingStudioPresskits::Engine.send(:apply_extensions, nil, [])
  end

  def test_extension_keys_for_includes_demodulized_name
    namespaced = Class.new do
      def self.name
        "Admin::ReportsController"
      end
    end

    expected_keys = [:"Admin::ReportsController"]
    expected_keys << :ReportsController

    assert_equal expected_keys, RecordingStudioPresskits::Engine.send(:extension_keys_for, namespaced)
  end

  def test_extension_keys_for_removes_duplicate_names
    plain = Class.new do
      def self.name
        "ReportsController"
      end
    end

    assert_equal [:ReportsController], RecordingStudioPresskits::Engine.send(:extension_keys_for, plain)
  end

  private

  def with_temporary_nested_constant(parent_name, child_name, value)
    parent_defined = Object.const_defined?(parent_name, false)
    parent = parent_defined ? Object.const_get(parent_name) : Object.const_set(parent_name, Module.new)
    child_defined = parent.const_defined?(child_name, false)
    previous_child = parent.const_get(child_name) if child_defined

    parent.const_set(child_name, value)
    yield
  ensure
    parent.send(:remove_const, child_name) if parent.const_defined?(child_name, false)
    parent.const_set(child_name, previous_child) if child_defined
    Object.send(:remove_const, parent_name) unless parent_defined
  end

  def find_initializer(name)
    RecordingStudioPresskits::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
