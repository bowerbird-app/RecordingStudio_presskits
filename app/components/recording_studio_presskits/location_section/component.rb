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

      def place_icon(place)
        return if defined?(RecordingStudioLocation) && RecordingStudioLocation.configuration.icon_mode_none?
        return unless place.respond_to?(:resolved_icon)

        place.resolved_icon.presence
      end

      def place_address(place)
        address = place.full_address.to_s.strip
        return if address.blank? || address == place.display_name

        address
      end
    end
  end
end
