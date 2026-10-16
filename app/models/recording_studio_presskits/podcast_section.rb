# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastSection < ApplicationRecord
    self.table_name = "recording_studio_podcast_sections"

    recording_studio_recordable label: "Podcasts",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "microphone"
    end

    def self.active_podcasts(recording)
      return RecordingStudio::Recording.none if recording.blank?

      recording.recording_studio_orderable_children
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .reorder(Arel.sql(ACTIVE_ORDER))
    end

    # A new episode has no position yet. Keep those after positioned ones so
    # the saved order stays in front.
    ACTIVE_ORDER = "recording_studio_recordings.recording_studio_orderable_position ASC NULLS LAST, " \
                   "recording_studio_recordings.created_at ASC, recording_studio_recordings.id ASC"

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::Podcast"])
  end
end
