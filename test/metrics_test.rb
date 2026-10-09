# frozen_string_literal: true

require "test_helper"

class MetricsTest < Minitest::Test
  def test_access_can_view_is_false_without_actor_or_admin_root
    context = Object.new
    def context.access_grant
      nil
    end

    refute RecordingStudioPresskits::Api::Access.can_view?(context)
  end

  def test_site_resolver_is_preferred_when_set
    config = RecordingStudioAdmin.configuration
    previous_site_resolver = config.site_admin_recording_resolver
    previous_access_resolver = config.access_recording_resolver
    site_root = Object.new
    access_called = false
    seen_root = nil

    config.site_admin_recording_resolver = ->(_context) { site_root }
    config.access_recording_resolver = lambda do |_context|
      access_called = true
      Object.new
    end

    RecordingStudioAccessible.stub(:authorized?, lambda { |recording:, **|
      seen_root = recording
      true
    }) do
      assert RecordingStudioPresskits::Api::Access.can_view?(metrics_actor_context)
    end

    assert_same site_root, seen_root
    refute access_called
  ensure
    config.site_admin_recording_resolver = previous_site_resolver
    config.access_recording_resolver = previous_access_resolver
  end

  def test_access_resolver_is_used_when_site_resolver_is_unset
    config = RecordingStudioAdmin.configuration
    previous_site_resolver = config.site_admin_recording_resolver
    previous_access_resolver = config.access_recording_resolver
    access_root = Object.new
    seen_root = nil

    config.site_admin_recording_resolver = nil
    config.access_recording_resolver = ->(_context) { access_root }

    RecordingStudioAccessible.stub(:authorized?, lambda { |recording:, **|
      seen_root = recording
      false
    }) do
      refute RecordingStudioPresskits::Api::Access.can_view?(metrics_actor_context)
    end

    assert_same access_root, seen_root
  ensure
    config.site_admin_recording_resolver = previous_site_resolver
    config.access_recording_resolver = previous_access_resolver
  end

  def test_resolver_error_denies_view_without_raising
    config = RecordingStudioAdmin.configuration
    previous_site_resolver = config.site_admin_recording_resolver
    previous_access_resolver = config.access_recording_resolver
    access_called = false

    config.site_admin_recording_resolver = ->(context) { context.controller.current_root_recording }
    config.access_recording_resolver = lambda do |_context|
      access_called = true
      Object.new
    end

    RecordingStudioAccessible.stub(:authorized?, true) do
      refute RecordingStudioPresskits::Api::Access.can_view?(metrics_actor_context)
    end

    refute access_called

    config.site_admin_recording_resolver = nil
    config.access_recording_resolver = ->(context) { context.controller.current_root_recording }

    RecordingStudioAccessible.stub(:authorized?, true) do
      refute RecordingStudioPresskits::Api::Access.can_view?(metrics_actor_context)
    end
  ensure
    config.site_admin_recording_resolver = previous_site_resolver
    config.access_recording_resolver = previous_access_resolver
  end

  def test_nil_resolver_result_denies_view
    config = RecordingStudioAdmin.configuration
    previous_site_resolver = config.site_admin_recording_resolver
    previous_access_resolver = config.access_recording_resolver
    access_called = false

    config.site_admin_recording_resolver = ->(_context) {}
    config.access_recording_resolver = lambda do |_context|
      access_called = true
      Object.new
    end

    RecordingStudioAccessible.stub(:authorized?, true) do
      refute RecordingStudioPresskits::Api::Access.can_view?(metrics_actor_context)
    end

    refute access_called
  ensure
    config.site_admin_recording_resolver = previous_site_resolver
    config.access_recording_resolver = previous_access_resolver
  end

  def test_metrics_constants_match_operations_press_kits
    assert_equal :press_kits, RecordingStudioPresskits::Metrics::RESOURCE
    assert_equal :operations, RecordingStudioPresskits::Metrics::API
    assert_equal({ api: [:operations] }, RecordingStudioPresskits::Metrics::EXPOSE)
  end

  private

  def metrics_actor_context
    actor = Object.new
    grant = Struct.new(:actor).new(actor)
    Struct.new(:access_grant).new(grant)
  end
end
