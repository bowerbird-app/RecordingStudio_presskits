# frozen_string_literal: true

class CreateRecordingStudioFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_files, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end
end
