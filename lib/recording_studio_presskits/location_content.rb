# frozen_string_literal: true

require "cgi"

module RecordingStudioPresskits
  # Press-kit integration around RecordingStudio::Location::Location.
  # Location owns the place. This module is the section glue: menu icon,
  # visibility, map link, and the attributes the section editor permits.
  module LocationContent
    TYPE_NAME = "RecordingStudio::Location::Location"
    MENU_ICON = "map-pin"
    # Names match RecordingStudio::Location::Location columns.
    # rubocop:disable Naming/VariableNumber
    ATTRIBUTES = %i[
      name
      address_line_1
      address_line_2
      locality
      region
      postal_code
      country_code
      latitude
      longitude
    ].freeze
    # rubocop:enable Naming/VariableNumber

    module MenuIcon
      def section_menu_icon
        MENU_ICON
      end
    end

    class << self
      def type?(recording_or_type)
        type_name(recording_or_type) == TYPE_NAME
      end

      def visible?(location)
        return false if location.blank?

        ATTRIBUTES.any? { |name| location.public_send(name).present? }
      end

      def map_url(location)
        return unless visible?(location)

        coords = location.coordinates
        return coordinate_map_url(coords) if coords

        query = location.full_address.presence || location.name.to_s.strip.presence
        return if query.blank?

        "https://www.openstreetmap.org/search?query=#{CGI.escape(query)}"
      end

      private

      def type_name(recording_or_type)
        if recording_or_type.respond_to?(:recordable_type)
          recording_or_type.recordable_type.to_s
        else
          recording_or_type.to_s
        end
      end

      def coordinate_map_url(coords)
        lat, lng = coords
        "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}#map=16/#{lat}/#{lng}"
      end
    end
  end
end
