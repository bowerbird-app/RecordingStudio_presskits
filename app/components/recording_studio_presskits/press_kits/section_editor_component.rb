# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionEditorComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end
    end
  end
end
