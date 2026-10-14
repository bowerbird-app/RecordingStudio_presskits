# frozen_string_literal: true

require "active_model"

module RecordingStudioPresskits
  class ListItemBatch
    include ActiveModel::Model

    class << self
      def model_name
        ActiveModel::Name.new(self, nil, "ListLines")
      end

      def for_section(section_recording)
        new(lines: ListSection.active_items(section_recording).map { |item| LineDraft.from_recording(item) })
      end

      def from_rows(rows)
        new(lines: Array(rows).map { |row| LineDraft.from_row(row) })
      end
    end

    attr_reader :lines

    def initialize(lines: [])
      @lines = lines
    end

    def lines_attributes=(rows)
      @lines = Array(rows).map { |row| LineDraft.from_row(row) }
    end

    class LineDraft
      include ActiveModel::Model

      attr_accessor :id, :icon, :key, :value, :destroy

      def self.from_recording(recording)
        item = recording.recordable
        new(id: recording.id, icon: item.icon, key: item.key, value: item.value)
      end

      def self.from_row(row)
        new(
          id: row[:id].to_s.strip.presence,
          icon: row[:icon],
          key: row[:key],
          value: row[:value],
          destroy: row[:_destroy]
        )
      end

      def persisted?
        id.present?
      end

      def marked_for_destruction?
        ActiveModel::Type::Boolean.new.cast(destroy)
      end

      def _destroy
        marked_for_destruction? ? "1" : "0"
      end

      def blank_new_row?
        id.blank? && !marked_for_destruction? && [icon, key, value].all? { |field| field.to_s.strip.blank? }
      end
    end
  end
end
