# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EditorActionButtonComponent < ViewComponent::Base
      def initialize(text:, icon:, href:, data: {})
        super()
        @text = text
        @icon = icon
        @href = href
        @data = data
      end

      def call
        render FlatPack::Button::Component.new(
          text: @text,
          icon: @icon,
          style: :default,
          size: :sm,
          href: @href,
          class: EditorChrome::MOBILE_ICON_CLASSES,
          aria: { label: @text },
          data: @data
        )
      end
    end
  end
end
