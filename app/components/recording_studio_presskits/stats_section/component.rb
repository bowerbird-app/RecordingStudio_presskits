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

      def formatted_value(recordable)
        recordable.formatted_value
      end

      def supporting_text(recordable)
        [recordable.description.to_s.strip.presence].compact
      end
    end
  end
end
