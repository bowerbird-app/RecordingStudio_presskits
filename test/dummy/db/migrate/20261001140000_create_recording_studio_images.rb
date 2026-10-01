# frozen_string_literal: true

class CreateRecordingStudioImages < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_images, id: :uuid do |t|
      t.text :caption
      t.datetime :created_at, null: false
    end
  end
end
