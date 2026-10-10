# frozen_string_literal: true

module RecordingStudioPresskits
  class LocationSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :location_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def locations
        LocationSection.active_locations(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def edit_path(location_recording)
        helpers.edit_press_kit_section_location_path(kit_recording, kit_section_recording, location_recording)
      end

      def remove_path(location_recording)
        helpers.press_kit_section_location_path(kit_recording, kit_section_recording, location_recording)
      end

      def location_title(location_recording)
        location_recording.recordable.display_name.presence || "Location"
      end

      def location_summary(location_recording)
        location_recording.recordable.full_address.presence
      end

      private

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
