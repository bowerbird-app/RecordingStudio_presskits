# frozen_string_literal: true

module RecordingStudioPresskits
  module Location
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
        @location = recording.recordable
      end

      def render?
        LocationContent.visible?(@location)
      end

      def display
        helpers.recording_studio_location_display(@location)
      end

      def map_url
        LocationContent.map_url(@location)
      end

      def map_link
        return unless map_url

        FlatPack::Button::Component.new(
          text: "Open map",
          href: map_url,
          style: :default,
          target: "_blank"
        )
      end
    end
  end
end
