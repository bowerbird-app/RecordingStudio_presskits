# frozen_string_literal: true

module RecordingStudioPresskits
  class MenuSection < ApplicationRecord
    self.table_name = "recording_studio_menu_sections"

    LAYOUTS = %w[grid list].freeze
    DEFAULT_LAYOUT = "grid"
    DEFAULT_TITLE = "Contents"
    DEFAULT_SUBTITLE = "Jump to any section of the press kit."

    Item = Struct.new(:label, :hidden, keyword_init: true) do
      def shown?
        !hidden
      end
    end

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

    def item_for(section_id)
      entry = normalize_entry(items_hash[section_id.to_s])
      Item.new(label: entry["label"], hidden: entry["hidden"])
    end

    def link_label(section, heading)
      item_for(section.id).label.presence || heading
    end

    def label_overridden?(section)
      item_for(section.id).label.present?
    end

    def hidden_section?(section)
      item_for(section.id).hidden
    end

    include RecordingStudio::Capabilities::Trashable.to

    validates :layout, inclusion: { in: LAYOUTS }

    before_validation :normalize_menu

    private

    def initialize_dup(other)
      super
      @source_recordable_id = other.id
    end

    def normalize_menu
      self.layout = DEFAULT_LAYOUT if layout.blank?
      self.show_counts = true if show_counts.nil?
      self.show_icons = true if show_icons.nil?
      self.items = cleaned_items
    end

    def cleaned_items
      live_ids = live_section_ids
      items_hash.each_with_object({}) do |(section_id, attrs), kept|
        keep_item(kept, section_id, attrs, live_ids)
      end
    end

    def keep_item(kept, section_id, attrs, live_ids)
      key = section_id.to_s
      return if key.blank?
      return if live_ids && !live_ids.include?(key)

      entry = normalize_entry(attrs)
      return if entry["label"].blank? && entry["hidden"] == false

      kept[key] = entry
    end

    def normalize_entry(attrs)
      hash = attrs.is_a?(Hash) ? attrs.stringify_keys : {}
      hidden = hash.key?("shown") ? !truthy?(hash["shown"]) : truthy?(hash["hidden"])
      { "label" => hash["label"].to_s.strip, "hidden" => hidden }
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def items_hash
      return {} unless items.is_a?(Hash)

      items.deep_stringify_keys
    end

    def live_section_ids
      kit = menu_kit
      return if kit.blank?

      KitQuery.sections_for(kit).map { |section| section.id.to_s }
    end

    def menu_kit
      menu_recording&.parent_recording&.parent_recording
    end

    def menu_recording
      source_id = @source_recordable_id.presence || id
      return if source_id.blank?

      RecordingStudio::Recording.find_by(recordable_type: self.class.name, recordable_id: source_id)
    end
  end
end
