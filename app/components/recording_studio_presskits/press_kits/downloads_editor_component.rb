# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class DownloadsEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, audience:, options:, constrained: false)
        super()
        @press_kit_recording = press_kit_recording
        @audience = audience
        @options = Array(options)
        @constrained = constrained
      end

      def audience_value
        @audience.to_s
      end

      def constrained?
        @constrained
      end

      def select_options
        @options.map { |option| { label: option[:label], value: option[:audience].to_s } }
      end
    end
  end
end
