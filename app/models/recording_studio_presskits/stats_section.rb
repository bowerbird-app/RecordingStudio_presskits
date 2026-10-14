# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection < ApplicationRecord
    self.table_name = "recording_studio_stats_sections"

    COLUMN_COUNTS = [2, 3, 4].freeze
    DEFAULT_COLUMNS = 3

    recording_studio_recordable label: "Stats",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "calculator"
    end

    def self.active_stats(recording)
      return [] if recording.blank?

      recording.recording_studio_orderable_children.reject { |child| hidden_stat?(child) }
    end

    def self.hidden_stat?(child)
      child.trashed_at.present? || !child.recordable.is_a?(Stat)
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::Stat"])

    attribute :columns, :integer, default: DEFAULT_COLUMNS

    validates :columns, inclusion: { in: COLUMN_COUNTS }

    before_validation :apply_defaults

    private

    def apply_defaults
      self.columns = columns.presence || DEFAULT_COLUMNS
    end
  end
end
