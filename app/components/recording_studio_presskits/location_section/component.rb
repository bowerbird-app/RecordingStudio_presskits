# frozen_string_literal: true

module RecordingStudioPresskits
  class LocationSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        locations.any?
      end

      def locations
        LocationSection.active_locations(@recording)
      end

      def display_for(location_recording)
        helpers.recording_studio_location_display(location_recording.recordable)
      end
    end
  end
end
