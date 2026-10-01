# frozen_string_literal: true

module RecordingStudioPresskits
  class Text < ApplicationRecord
    self.table_name = "recording_studio_texts"

    recording_studio_recordable label: "Text",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::PressKit"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :body, presence: true

    def title
      body.to_s.strip.lines.first.to_s.strip.truncate(80).presence
    end
  end
end
