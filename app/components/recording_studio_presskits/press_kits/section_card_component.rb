# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionCardComponent < ViewComponent::Base
      def call
        render FlatPack::Card::Component.new(
          style: :default,
          hover: :none,
          padding: :none,
          class: EditorChrome::SECTION_CARD_CLASSES,
          data: { section_card: true }
        ) do
          content
        end
      end
    end
  end
end
