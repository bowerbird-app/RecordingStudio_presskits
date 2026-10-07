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
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: [:image],
      max_file_size: 25.megabytes,
      max_file_count: 20,
      auth_roles: { remove: :edit }
    )
  end
end
