# frozen_string_literal: true

class DropColumnsFromRecordingStudioStatsSections < ActiveRecord::Migration[8.1]
  def up
    self.class.drop_columns
  end

  def self.drop_columns
    connection = ActiveRecord::Base.connection
    return unless connection.data_source_exists?("recording_studio_stats_sections")
    return unless connection.column_exists?(:recording_studio_stats_sections, :columns)

    connection.remove_column :recording_studio_stats_sections, :columns
  end
end
