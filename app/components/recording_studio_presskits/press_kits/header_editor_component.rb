# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, title:, description:)
        super()
        @press_kit_recording = press_kit_recording
        @title = title
        @description = description
      end

      def header_title
        @title.to_s
      end

      def header_description
        @description.to_s
      end

      def cancel_path
        helpers.edit_press_kit_path(@press_kit_recording)
      end
    end
  end
end
