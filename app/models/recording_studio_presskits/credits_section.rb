# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection < ApplicationRecord
    self.table_name = "recording_studio_credits_sections"

    recording_studio_recordable label: "Credits",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "user-group"
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::CreditLine"])
  end
end
