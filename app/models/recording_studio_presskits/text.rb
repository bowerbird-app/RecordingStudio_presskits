# frozen_string_literal: true

module RecordingStudioPresskits
  class Text < ApplicationRecord
    self.table_name = "recording_studio_texts"

    OPENING_BODY = [
      "<h2>Launch notes</h2>",
      "<p>Doors at noon. Bring the <strong>one-sheet</strong>.</p>",
      "<ul><li>Photos</li><li>Bio</li></ul>"
    ].join.freeze

    recording_studio_recordable label: "Text",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "document-text"
    end

    include RecordingStudio::Capabilities::Trashable.to

    validates :body, presence: true

    before_validation :sanitize_body

    def self.opening_body
      OPENING_BODY
    end

    private

    def sanitize_body
      cleaned = body.to_s.gsub(%r{<(script|style)\b[^>]*>.*?</\1>}mi, "")
      self.body = FlatPack::RichTextSanitizer.sanitize(cleaned).to_s
    end
  end
end
