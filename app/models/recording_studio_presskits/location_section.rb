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

      recording.recording_studio_orderable_children
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .reorder(Arel.sql(ACTIVE_ORDER))
    end

    # A new place has no position yet. Keep those after positioned ones so
    # the saved order stays in front.
    ACTIVE_ORDER = "recording_studio_recordings.recording_studio_orderable_position ASC NULLS LAST, " \
                   "recording_studio_recordings.created_at ASC, recording_studio_recordings.id ASC"

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Location.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudio::Location::Location"])
  end
end
