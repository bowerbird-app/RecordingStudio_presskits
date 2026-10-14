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

      def icon_component(recordable)
        FlatPack::Shared::IconComponent.new(name: recordable.icon, size: :md)
      end

      private

      def visible?(recordable)
        recordable.key.to_s.strip.present? && recordable.value.to_s.strip.present?
      end
    end
  end
end
