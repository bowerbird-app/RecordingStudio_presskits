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

      def icon_cell(recording)
        name = recording.recordable.icon
        return tag.span(data: { list_item: true }) if name.blank?

        tag.span(data: { list_item: true }) do
          render(FlatPack::Shared::IconComponent.new(name: name, size: :md))
        end
      end

      def clipped(text, muted:)
        tag.span(text, class: clip_classes(muted))
      end

      private

      def clip_classes(muted)
        tone = muted ? "text-(--surface-muted-content-color)" : "font-medium text-(--surface-content-color)"
        "block max-w-full truncate whitespace-nowrap #{tone}"
      end

      def visible?(recordable)
        recordable.key.to_s.strip.present? && recordable.value.to_s.strip.present?
      end
    end
  end
end
