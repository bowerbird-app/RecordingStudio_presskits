# frozen_string_literal: true

module RecordingStudioPresskits
  class Images < ApplicationRecord
    self.table_name = "recording_studio_images"

    recording_studio_recordable label: "Images",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "photo"
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::LibraryPlacement.to
    include RecordingStudio::Capabilities::Orderable.to(
      allows: ["RecordingStudioAttachable::Placement"]
    )
  end
end
