# frozen_string_literal: true

module RecordingStudioPresskits
  class ListSection
    class Component < ViewComponent::Base
      # One text column. Two columns are that measure twice, plus the grid's large gap.
      NARROW_MEASURE = "max-w-[65ch]"
      WIDE_MEASURE = "max-w-[calc(130ch+1.5rem)]"
      SINGLE_LIST_LIMIT = 6

      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        items.any?
      end

      def items
        ListSection.active_items(@recording).select { |child| visible?(child.recordable) }
      end

      def line_columns
        @line_columns ||= self.class.line_columns(items)
      end

      def wide?
        line_columns.size > 1
      end

      def measure_class
        wide? ? WIDE_MEASURE : NARROW_MEASURE
      end

      def self.line_columns(rows)
        rows = Array(rows)
        return [rows] unless rows.size > SINGLE_LIST_LIMIT

        midpoint = (rows.size / 2.0).ceil
        [rows.take(midpoint), rows.drop(midpoint)]
      end

      private

      def visible?(recordable)
        recordable.key.to_s.strip.present? && recordable.value.to_s.strip.present?
      end
    end
  end
end
