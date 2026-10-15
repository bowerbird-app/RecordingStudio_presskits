# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class IndexComponent < ViewComponent::Base
      def initialize(press_kit_recordings:, view:, cards_path:, table_path:, new_path:, show_path:) # rubocop:disable Metrics/ParameterLists
        super()
        @press_kit_recordings = press_kit_recordings
        @view = view.to_s
        @cards_path = cards_path
        @table_path = table_path
        @new_path = new_path
        @show_path = show_path
      end

      def table_view?
        @view == "table"
      end
    end
  end
end
