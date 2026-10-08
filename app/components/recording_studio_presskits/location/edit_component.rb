# frozen_string_literal: true

module RecordingStudioPresskits
  module Location
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @location = recording.recordable
        @update_path = update_path
      end

      def self.param_key
        :location
      end

      def self.permitted_attributes
        LocationContent::ATTRIBUTES
      end

      def fields
        helpers.fields_for(self.class.param_key, @location) do |form|
          helpers.recording_studio_location_fields(form)
        end
      end
    end
  end
end
