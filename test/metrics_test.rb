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

  def test_metrics_constants_match_operations_press_kits
    assert_equal :press_kits, RecordingStudioPresskits::Metrics::RESOURCE
    assert_equal :operations, RecordingStudioPresskits::Metrics::API
    assert_equal({ api: [:operations] }, RecordingStudioPresskits::Metrics::EXPOSE)
  end
end
