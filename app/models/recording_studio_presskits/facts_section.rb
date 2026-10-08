# frozen_string_literal: true

module RecordingStudioPresskits
  class FactsSection < ApplicationRecord
    self.table_name = "recording_studio_facts_sections"

    DISPLAY_STYLES = %w[list cards table].freeze
    COLUMN_COUNTS = [2, 3, 4].freeze
    DEFAULT_DISPLAY_STYLE = "list"
    DEFAULT_COLUMNS = 3

    recording_studio_recordable label: "Facts & Figures",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "calculator"
    end

    def self.active_facts(recording)
      return [] if recording.blank?

      recording.recording_studio_orderable_children.reject { |child| hidden_fact?(child) }
    end

    def self.hidden_fact?(child)
      child.trashed_at.present? || !child.recordable.is_a?(Fact)
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::Fact"])

    attribute :display_style, :string, default: DEFAULT_DISPLAY_STYLE
    attribute :columns, :integer, default: DEFAULT_COLUMNS

    validates :display_style, inclusion: { in: DISPLAY_STYLES }
    validates :columns, inclusion: { in: COLUMN_COUNTS }

    before_validation :apply_defaults

    def cards?
      display_style == "cards"
    end

    def table?
      display_style == "table"
    end

    def list?
      display_style == "list"
    end

    private

    def apply_defaults
      self.display_style = display_style.to_s.strip.presence || DEFAULT_DISPLAY_STYLE
      self.columns = columns.presence || DEFAULT_COLUMNS
    end
  end
end
