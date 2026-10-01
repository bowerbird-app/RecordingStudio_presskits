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
                                allowed_parent_types: ["RecordingStudioPresskits::PressKit"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :body, presence: true

    before_validation :sanitize_body

    def self.opening_body
      OPENING_BODY
    end

    def title
      plain = ActionController::Base.helpers.strip_tags(body_with_breaks)
      plain.strip.lines.first.to_s.strip.truncate(80).presence
    end

    private

    def sanitize_body
      cleaned = body.to_s.gsub(%r{<(script|style)\b[^>]*>.*?</\1>}mi, "")
      self.body = FlatPack::RichTextSanitizer.sanitize(cleaned).to_s
    end

    def body_with_breaks
      with_breaks = body.to_s.gsub(%r{</(?:h[1-6]|p|li|div|blockquote)>}i, "\n")
      with_breaks.gsub(%r{<br\s*/?>}i, "\n")
    end
  end
end
