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

    # recording.videos keeps trashed children. Lists use the active scope.
    def self.active_videos(recording)
      return RecordingStudio::Recording.none if recording.blank?

      recording.videos
               .merge(RecordingStudio::Recording.recording_studio_trashable_active)
               .reorder(:created_at)
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Videos.to
  end
end
