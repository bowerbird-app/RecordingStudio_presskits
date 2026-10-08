# frozen_string_literal: true

module RecordingStudioPresskits
  class Fact < ApplicationRecord
    self.table_name = "recording_studio_facts"

    HTTP_URL = /\Ahttps?:\/\/[^\s]+\z/i

    recording_studio_recordable label: "Fact",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::FactsSection"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :label, presence: true
    validates :value, presence: true
    validates :source_url, format: {
      with: HTTP_URL,
      message: "must be an HTTP or HTTPS link"
    }, allow_blank: true

    before_validation :clear_blank_details

    def title
      label.to_s.strip.presence || "Fact"
    end

    def formatted_value
      [value, unit].filter_map { |part| part.to_s.strip.presence }.join(" ")
    end

    private

    def clear_blank_details
      self.label = label.to_s.strip
      self.value = value.to_s.strip
      self.unit = unit.to_s.strip.presence
      self.description = description.to_s.strip.presence
      self.source_url = source_url.to_s.strip.presence
    end
  end
end
