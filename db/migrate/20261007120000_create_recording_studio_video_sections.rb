# frozen_string_literal: true

class CreateRecordingStudioVideoSections < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_video_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end
end
