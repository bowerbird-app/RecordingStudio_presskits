# frozen_string_literal: true

module RecordingStudioPresskits
  class Files < ApplicationRecord
    self.table_name = "recording_studio_files"

    # Attachable matches these MIME types only. No images, HTML, or SVG.
    ALLOWED_CONTENT_TYPES = %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      text/csv
      application/csv
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      text/plain
      application/zip
      application/x-zip-compressed
    ].freeze

    MAX_FILE_BYTES = 25.megabytes
    MAX_FILES = 10

    recording_studio_recordable label: "Files",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "paper-clip"
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ALLOWED_CONTENT_TYPES,
      enabled_attachment_kinds: [:file],
      max_file_size: MAX_FILE_BYTES,
      max_file_count: MAX_FILES,
      auth_roles: { remove: :edit },
      authorize_with: FileAccess
    )
    include RecordingStudio::Capabilities::Orderable.to(
      allows: ["RecordingStudioAttachable::Attachment"]
    )
  end
end
