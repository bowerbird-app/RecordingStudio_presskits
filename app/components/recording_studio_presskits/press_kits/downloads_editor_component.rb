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

      def radio_options
        @options.map do |option|
          audience = option[:audience]
          {
            label: option[:label],
            value: audience.to_s,
            icon: KitDownload.audience_icon_for(audience)
          }
        end
      end
    end
  end
end
