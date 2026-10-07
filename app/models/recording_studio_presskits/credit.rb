# frozen_string_literal: true

module RecordingStudioPresskits
  class Credit < ApplicationRecord
    self.table_name = "recording_studio_credits"

    recording_studio_recordable label: "Credit",
                                root: false,
                                allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

    include RecordingStudio::Capabilities::Trashable.to

    validates :name, presence: true

    before_validation :clear_blank_details

    def title
      name.to_s.strip.presence || "Credit"
    end

    private

    def clear_blank_details
      self.name = name.to_s.strip
      self.url = url.to_s.strip.presence
      self.usual_role = usual_role.to_s.strip.presence
    end
  end
end
