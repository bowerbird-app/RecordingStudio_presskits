# frozen_string_literal: true

class CreateRecordingStudioVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_videos, id: :uuid do |t|
      t.string :title
      t.text :url, null: false
      t.text :description
      t.datetime :created_at, null: false
    end
  end
end
