# frozen_string_literal: true

module RecordingStudioPresskits
  class FactsSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        facts.any?
      end

      def facts
        FactsSection.active_facts(@recording)
      end

      def section
        @recording.recordable
      end

      def cards?
        section.cards?
      end

      def table?
        section.table?
      end

      def columns
        section.columns
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

      def source_url(recordable)
        FlatPack::AttributeSanitizer.sanitize_url(recordable.source_url)
      end

      def grid_class
        "grid-cols-1 sm:grid-cols-2 lg:grid-cols-#{columns}"
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
