# frozen_string_literal: true

class RenameRecordingStudioFactsToStats < ActiveRecord::Migration[8.1]
  def up
    rename_legacy_tables
    drop_display_style
    self.class.rewrite_recordable_types
  end

  def self.rewrite_recordable_types
    connection = ActiveRecord::Base.connection
    return unless connection.data_source_exists?("recording_studio_recordings")

    connection.execute(<<~SQL.squish)
      UPDATE recording_studio_recordings
      SET recordable_type = 'RecordingStudioPresskits::StatsSection'
      WHERE recordable_type = 'RecordingStudioPresskits::FactsSection'
    SQL
    connection.execute(<<~SQL.squish)
      UPDATE recording_studio_recordings
      SET recordable_type = 'RecordingStudioPresskits::Stat'
      WHERE recordable_type = 'RecordingStudioPresskits::Fact'
    SQL
  end

  private

  def rename_legacy_tables
    if table_exists?(:recording_studio_facts_sections) && !table_exists?(:recording_studio_stats_sections)
      rename_table :recording_studio_facts_sections, :recording_studio_stats_sections
    end

    if table_exists?(:recording_studio_facts) && !table_exists?(:recording_studio_stats)
      rename_table :recording_studio_facts, :recording_studio_stats
    end
  end

  def drop_display_style
    return unless table_exists?(:recording_studio_stats_sections)
    return unless column_exists?(:recording_studio_stats_sections, :display_style)

    remove_column :recording_studio_stats_sections, :display_style
  end
end
