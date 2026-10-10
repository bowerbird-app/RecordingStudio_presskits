# frozen_string_literal: true

module RecordingStudioPresskits
  class LocationSection < ApplicationRecord
    self.table_name = "recording_studio_location_sections"

    TYPE = "RecordingStudio::Location::Location"

    recording_studio_recordable label: "Location",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "map-pin"
    end

    def self.active_locations(recording)
      return RecordingStudio::Recording.none if recording.blank?

      recording.child_recordings
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .where(recordable_type: TYPE)
               .reorder(:created_at, :id)
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Location.to
  end
end
