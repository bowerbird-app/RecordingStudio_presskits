# frozen_string_literal: true

module RecordingStudioPresskits
  class KitSection < ApplicationRecord
    self.table_name = "recording_studio_kit_sections"

    recording_studio_recordable label: "Section",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::PressKit"]

    include RecordingStudio::Capabilities::Trashable.to

    before_validation :clear_blank_headings

    private

    # Duplicating a kit appends " (Copy)" to a blank title. That is not a heading.
    def clear_blank_headings
      self.title = heading_or_nil(title)
      self.subtitle = heading_or_nil(subtitle)
    end

    def heading_or_nil(value)
      stripped = value.to_s.strip
      return if stripped.blank? || stripped == "(Copy)"

      stripped
    end
  end
end
