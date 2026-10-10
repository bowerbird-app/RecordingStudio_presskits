# frozen_string_literal: true

module RecordingStudioPresskits
  module Locations
    class EditComponent < ViewComponent::Base
      attr_reader :location

      def initialize(location:, section_recording:, location_recording: nil)
        super()
        @location = location
        @section_recording = section_recording
        @location_recording = location_recording
      end

      def heading
        location.display_name.presence || "Location"
      end

      def form_path
        if @location_recording&.persisted?
          helpers.press_kit_section_location_path(kit_recording, @section_recording, @location_recording)
        else
          helpers.press_kit_section_locations_path(kit_recording, @section_recording)
        end
      end

      def form_method
        @location_recording&.persisted? ? :patch : :post
      end

      def form_data
        @location_recording&.persisted? ? helpers.presskits_editor_save_data : {}
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
