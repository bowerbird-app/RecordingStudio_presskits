# frozen_string_literal: true

module RecordingStudioPresskits
  class ListItem < ApplicationRecord
    self.table_name = "recording_studio_kit_list_items"

    recording_studio_recordable label: "Item",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::ListSection"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :key, presence: true
    validates :value, presence: true
    validate :icon_is_known

    before_validation :clear_blank_fields

    private

    def clear_blank_fields
      self.key = key.to_s.strip
      self.value = value.to_s.strip
      self.icon = stored_icon
    end

    def stored_icon
      raw = icon.to_s.strip.tr("_", "-").presence
      return if raw.blank?

      Icons.canonical(raw) || raw
    end

    def icon_is_known
      return if icon.blank?
      return if Icons.known?(icon)

      errors.add(:icon, "is not a Flatpack icon")
    end
  end
end
