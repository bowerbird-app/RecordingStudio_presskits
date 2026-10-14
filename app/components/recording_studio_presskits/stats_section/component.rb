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
        [
          recordable.description.to_s.strip.presence,
          as_of_text(recordable)
        ].compact
      end

      private

      def as_of_text(recordable)
        date = recordable.as_of_date
        return if date.blank?

        "As of #{date}"
      end
    end
  end
end
