# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection < ApplicationRecord
    self.table_name = "recording_studio_stats_sections"

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
      child.recording_studio_trashable_trashed? || !child.recordable.is_a?(Stat)
    end

    def self.copy_text(stats, title: nil)
      lines = stats.filter_map { |recording| copy_line(recording.recordable) }
      heading = title.to_s.strip.presence
      [heading, *lines].compact.join("\n")
    end

    def self.copy_line(stat)
      label = stat.label.to_s.strip
      value = stat.formatted_value.to_s.strip
      return if label.blank? || value.blank?

      line = "#{value} #{label}"
      description = stat.description.to_s.strip.presence
      description ? "#{line} – #{description}" : line
    end
    private_class_method :copy_line

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::Stat"])
  end
end
