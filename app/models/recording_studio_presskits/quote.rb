# frozen_string_literal: true

module RecordingStudioPresskits
  class Quote < ApplicationRecord
    self.table_name = "recording_studio_quotes"

    recording_studio_recordable label: "Quote",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::QuoteSection"]

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: [:image],
      max_file_size: 10.megabytes,
      max_file_count: 1,
      auth_roles: { remove: :edit }
    )

    def title
      name.to_s.strip.truncate(80).presence || "Quote"
    end
  end
end
