# frozen_string_literal: true

module RecordingStudioPresskits
  class ListSection
    class CopyButtonComponent < ViewComponent::Base
      def self.for(content)
        return unless content&.recordable.is_a?(ListSection)

        text = ListSection.copy_text(ListSection.active_items(content))
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
