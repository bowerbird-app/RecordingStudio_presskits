# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteSection < ApplicationRecord
    self.table_name = "recording_studio_quote_sections"

    recording_studio_recordable label: "Quotes",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "chat-bubble-bottom-center-text"
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::Quote"])
  end
end
