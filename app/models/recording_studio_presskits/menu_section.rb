# frozen_string_literal: true

module RecordingStudioPresskits
  class MenuSection < ApplicationRecord
    self.table_name = "recording_studio_menu_sections"

    LAYOUTS = %w[grid list].freeze
    DEFAULT_LAYOUT = "grid"
    DEFAULT_TITLE = "Contents"
    DEFAULT_SUBTITLE = "Jump to any section of the press kit."

    recording_studio_recordable label: "Menu",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "queue-list"
    end

    def self.default_title
      DEFAULT_TITLE
    end

    def self.default_subtitle
      DEFAULT_SUBTITLE
    end

    def prepare_defaults
      normalize_menu
    end

    include RecordingStudio::Capabilities::Trashable.to

    validates :layout, inclusion: { in: LAYOUTS }

    before_validation :normalize_menu

    private

    def normalize_menu
      self.layout = DEFAULT_LAYOUT if layout.blank?
      self.show_counts = true if show_counts.nil?
      self.show_icons = true if show_icons.nil?
      self.excluded_section_ids = normalized_excluded_ids
    end

    def normalized_excluded_ids
      Array(excluded_section_ids).filter_map { |section_id| section_id.to_s.strip.presence }.uniq
    end
  end
end
