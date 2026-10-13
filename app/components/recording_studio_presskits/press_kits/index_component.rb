# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class IndexComponent < ViewComponent::Base
      def initialize(press_kit_recordings:, view:, cards_path:, table_path:, new_path:, show_path:, credits_path:, # rubocop:disable Metrics/ParameterLists
                     featured_recording: nil)
        super()
        @press_kit_recordings = press_kit_recordings
        @view = view.to_s
        @cards_path = cards_path
        @table_path = table_path
        @new_path = new_path
        @show_path = show_path
        @credits_path = credits_path
        @featured_recording = featured_recording
      end

      def table_view?
        @view == "table"
      end

      attr_reader :featured_recording

      def featured_card?
        !table_view? && featured_recording.present?
      end
    end
  end
end
