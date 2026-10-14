# frozen_string_literal: true

class AddIconToRecordingStudioStats < ActiveRecord::Migration[8.1]
  def up
    self.class.add_icon
  end

  def self.add_icon
    connection = ActiveRecord::Base.connection
    return unless connection.data_source_exists?("recording_studio_stats")
    return if connection.column_exists?(:recording_studio_stats, :icon)

    connection.add_column :recording_studio_stats, :icon, :string
  end
end
