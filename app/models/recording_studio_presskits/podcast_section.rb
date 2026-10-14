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

      recording.child_recordings
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .where(recordable_type: Podcast.name)
               .reorder(:created_at, :id)
    end

    include RecordingStudio::Capabilities::Trashable.to
  end
end
