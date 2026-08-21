# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionPickerComponent < ViewComponent::Base
      def initialize(items:, add_path:)
        super()
        @items = items
        @add_path = add_path
      end
    end
  end
end
