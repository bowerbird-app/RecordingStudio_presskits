# frozen_string_literal: true

module RecordingStudioPresskits
  class Stat < ApplicationRecord
    self.table_name = "recording_studio_stats"

    recording_studio_recordable label: "Stat",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::StatsSection"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :label, presence: true
    validates :value, presence: true

    before_validation :clear_blank_details

    def formatted_value
      [value, unit].filter_map { |part| part.to_s.strip.presence }.join(" ")
    end

    private

    def clear_blank_details
      self.label = stripped(label)
      self.value = stripped(value)
      self.unit = blank_to_nil(unit)
      self.description = blank_to_nil(description)
    end

    def stripped(value)
      value.to_s.strip
    end

    def blank_to_nil(value)
      stripped(value).presence
    end
  end
end
