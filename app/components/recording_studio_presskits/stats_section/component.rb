# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        stats.any?
      end

      def stats
        StatsSection.active_stats(@recording)
      end
    end
  end
end
