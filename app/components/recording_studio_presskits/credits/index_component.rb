# frozen_string_literal: true

module RecordingStudioPresskits
  module Credits
    class IndexComponent < ViewComponent::Base
      def initialize(credit_recordings:, new_path:, edit_path:)
        super()
        @credit_recordings = credit_recordings
        @new_path = new_path
        @edit_path = edit_path
      end

      def rows
        @credit_recordings
      end

      def edit_href(recording)
        @edit_path.call(recording)
      end
    end
  end
end
