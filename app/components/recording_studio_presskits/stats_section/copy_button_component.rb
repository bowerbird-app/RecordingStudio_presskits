# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection
    class CopyButtonComponent < ViewComponent::Base
      def self.for(content, title:)
        return unless content&.recordable.is_a?(StatsSection)

        stats = StatsSection.active_stats(content)
        return if stats.empty?

        text = StatsSection.copy_text(stats, title: title)
        return if text.blank?

        new(text: text)
      end

      def initialize(text:)
        super()
        @text = text
      end

      def call
        render FlatPack::CopyButton::Component.new(**button_options)
      end

      private

      def button_options
        {
          text: @text,
          label: "Copy",
          icon: "clipboard-document",
          style: :default,
          size: :sm
        }
      end
    end
  end
end
