# frozen_string_literal: true

class AddPresskitDetailsToRecordingStudioVideos < ActiveRecord::Migration[8.1]
  def change
    change_table :recording_studio_videos, bulk: true do |t|
      t.integer :duration_seconds
      t.text :thumbnail_url
    end
  end
end
