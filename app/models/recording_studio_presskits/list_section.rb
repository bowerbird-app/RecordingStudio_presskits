# frozen_string_literal: true

module RecordingStudioPresskits
  class ListSection < ApplicationRecord
    self.table_name = "recording_studio_list_sections"

    recording_studio_recordable label: "List",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "list-bullet"
    end

    def self.active_items(recording)
      return [] if recording.blank?

      recording.recording_studio_orderable_children.reject { |child| hidden_item?(child) }
    end

    def self.hidden_item?(child)
      child.recording_studio_trashable_trashed? || !child.recordable.is_a?(ListItem)
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::ListItem"])
  end
end
