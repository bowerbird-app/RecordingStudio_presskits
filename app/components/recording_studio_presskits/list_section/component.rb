# frozen_string_literal: true

module RecordingStudioPresskits
  class ListSection
    class Component < ViewComponent::Base
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

      private

      def visible?(recordable)
        recordable.key.to_s.strip.present? && recordable.value.to_s.strip.present?
      end
    end
  end
end
