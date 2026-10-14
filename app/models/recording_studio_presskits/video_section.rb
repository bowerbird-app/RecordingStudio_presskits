# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoSection < ApplicationRecord
    self.table_name = "recording_studio_video_sections"

    recording_studio_recordable label: "Video",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "video-camera"
    end

    def self.active_videos(recording)
      return RecordingStudio::Recording.none if recording.blank?

      recording.recording_studio_orderable_children
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .reorder(Arel.sql(ACTIVE_ORDER))
    end

    # A new video has no position yet. Keep those after positioned ones so the
    # featured card stays the one someone dragged to the front.
    ACTIVE_ORDER = "recording_studio_recordings.recording_studio_orderable_position ASC NULLS LAST, " \
                   "recording_studio_recordings.created_at ASC, recording_studio_recordings.id ASC"

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Videos.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioVideo::Video"])
  end
end
