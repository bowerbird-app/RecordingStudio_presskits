# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class IndexComponent < ViewComponent::Base
      def initialize(press_kit_recordings:, status:, query:, new_path:, show_path:)
        super()
        @press_kit_recordings = press_kit_recordings
        @status = KitIndex.status_from(status)
        @query = query.to_s
        @new_path = new_path
        @show_path = show_path
      end

      def filtered?
        @status != "all" || @query.strip.present?
      end

      def status_selected?(name)
        @status == name
      end

      def filter_path(status:)
        helpers.presskits_index_path(status: status, query: @query)
      end

      def search_path
        helpers.presskits_index_path(status: @status)
      end
    end
  end
end
