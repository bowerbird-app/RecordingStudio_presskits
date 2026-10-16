# frozen_string_literal: true

require "test_helper"

class KitDownloadGateTest < Minitest::Test
  def setup
    @downloadable_already_defined = defined?(RecordingStudioDownloadable)
  end

  def teardown
    return if @downloadable_already_defined
    return unless defined?(RecordingStudioDownloadable)

    Object.send(:remove_const, :RecordingStudioDownloadable)
  end

  def test_register_is_a_no_op_without_downloadable
    skip "Downloadable is loaded in this process" if defined?(RecordingStudioDownloadable)

    assert_nil RecordingStudioPresskits::KitDownloadGate.register!
  end

  def test_register_wires_kit_and_images_actions
    gates = {}
    config = Object.new
    config.define_singleton_method(:register_download_gate) do |action, gate|
      gates[action] = gate
    end
    downloadable = Module.new do
      define_singleton_method(:configure) { |&block| block.call(config) }
    end
    Object.const_set(:RecordingStudioDownloadable, downloadable)

    RecordingStudioPresskits::KitDownloadGate.register!

    assert_equal RecordingStudioPresskits::KitDownloadGate, gates[:"presskits.kit_download"]
    assert_equal RecordingStudioPresskits::KitDownloadGate, gates[:"presskits.images_download"]
  end

  def test_one_confirmation_covers_the_kit_and_its_images
    with_recordable_types do
      confirm_gate_covers_kit_and_images
    end
  end

  def confirm_gate_covers_kit_and_images
    kit = recording("kit-1", press_kit)
    images = recording("images-1", images_recordable, parent: recording("section-1", Object.new, parent: kit))
    session = {
      presskits_download_gate: {
        "kit-1" => { "confirmed" => true }
      }
    }
    request = Struct.new(:session).new(session)

    assert RecordingStudioPresskits::KitDownloadGate.covers?(kit)
    assert RecordingStudioPresskits::KitDownloadGate.covers?(images)
    refute RecordingStudioPresskits::KitDownloadGate.covers?(recording("other", Object.new))
    assert RecordingStudioPresskits::KitDownloadGate.satisfied?(recording: kit, actor: nil, request: request)
    assert RecordingStudioPresskits::KitDownloadGate.satisfied?(recording: images, actor: nil, request: request)
    refute RecordingStudioPresskits::KitDownloadGate.satisfied?(
      recording: kit,
      actor: nil,
      request: Struct.new(:session).new({})
    )
  end

  def test_metadata_copies_a_confirmed_gate
    with_recordable_types do
      copy_confirmed_metadata
    end
  end

  def copy_confirmed_metadata
    kit = recording("kit-1", press_kit)
    install_current!

    Current.download_gate = { "kit-1" => { "confirmed" => true } }
    assert_equal(
      { "confirmed" => true },
      RecordingStudioPresskits::KitDownloadGate.metadata_for(recording: kit, actor: nil)
    )

    Current.download_gate = { "kit-1" => { "confirmed" => "true" } }
    assert_equal({}, RecordingStudioPresskits::KitDownloadGate.metadata_for(recording: kit, actor: nil))
  ensure
    remove_current!
  end

  def test_paths_come_from_the_mounted_engine
    recording = Struct.new(:id).new("kit-1")
    helpers = Object.new
    helpers.define_singleton_method(:download_gate_path) do |**kwargs|
      id = kwargs[:recording_id]
      id ? "/presskits/download_gate?recording_id=#{id}" : "/presskits/download_gate"
    end
    routes = Object.new
    routes.define_singleton_method(:url_helpers) { helpers }

    RecordingStudioPresskits::Engine.stub(:routes, routes) do
      assert_equal "/presskits/download_gate", RecordingStudioPresskits::KitDownloadGate.form_path
      assert_equal(
        "/presskits/download_gate?recording_id=kit-1",
        RecordingStudioPresskits::KitDownloadGate.continuation_url(recording: recording, actor: nil, request: nil)
      )
    end
  end

  def test_engine_registers_the_gate_on_boot
    engine = File.read(File.expand_path("../lib/recording_studio_presskits/engine.rb", __dir__))

    assert_includes engine, "ImagesDownload.configure_audience!"
    assert_includes engine, "KitDownloadGate.register!"
    assert_includes engine, "remember_presskits_download_gate"
    routes = File.read(File.expand_path("../config/routes.rb", __dir__))
    assert_includes routes, "resource :download_gate"
    refute_includes routes, "image_archives"
  end

  private

  def with_recordable_types
    had_press_kit = RecordingStudioPresskits.const_defined?(:PressKit, false)
    had_images = RecordingStudioPresskits.const_defined?(:Images, false)
    RecordingStudioPresskits.const_set(:PressKit, Class.new) unless had_press_kit
    RecordingStudioPresskits.const_set(:Images, Class.new) unless had_images
    yield
  ensure
    RecordingStudioPresskits.send(:remove_const, :PressKit) unless had_press_kit
    RecordingStudioPresskits.send(:remove_const, :Images) unless had_images
  end

  def install_current!
    @created_current = !defined?(Current)
    return if defined?(Current)

    current = Class.new do
      class << self
        attr_accessor :download_gate
      end
    end
    Object.const_set(:Current, current)
  end

  def remove_current!
    return unless @created_current
    return unless defined?(Current)

    Object.send(:remove_const, :Current)
  end

  def recording(id, recordable, parent: nil)
    Struct.new(:id, :recordable, :parent_recording).new(id, recordable, parent)
  end

  def press_kit
    recordable = Object.new
    recordable.define_singleton_method(:is_a?) { |klass| klass == RecordingStudioPresskits::PressKit }
    recordable
  end

  def images_recordable
    recordable = Object.new
    recordable.define_singleton_method(:is_a?) { |klass| klass == RecordingStudioPresskits::Images }
    recordable
  end
end
