# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionsOrderComponent < ViewComponent::Base
      def initialize(section_recordings:, remove_path:, edit_path:, reorder_path:)
        super()
        @section_recordings = Array(section_recordings)
        @remove_path = remove_path
        @edit_path = edit_path
        @reorder_path = reorder_path
      end
    end
  end
end
