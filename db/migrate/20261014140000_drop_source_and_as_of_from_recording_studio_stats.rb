# frozen_string_literal: true

class DropSourceAndAsOfFromRecordingStudioStats < ActiveRecord::Migration[8.1]
  def up
    self.class.drop_source_and_as_of
  end

  def self.drop_source_and_as_of
    connection = ActiveRecord::Base.connection
    return unless connection.data_source_exists?("recording_studio_stats")

    if connection.column_exists?(:recording_studio_stats, :source_url)
      connection.remove_column :recording_studio_stats, :source_url
    end

    return unless connection.column_exists?(:recording_studio_stats, :as_of_date)

    connection.remove_column :recording_studio_stats, :as_of_date
  end
end
