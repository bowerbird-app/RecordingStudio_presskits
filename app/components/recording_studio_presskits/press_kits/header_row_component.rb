# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderRowComponent < ViewComponent::Base
      def initialize(edit_path:)
        super()
        @edit_path = edit_path
      end
    end
  end
end
