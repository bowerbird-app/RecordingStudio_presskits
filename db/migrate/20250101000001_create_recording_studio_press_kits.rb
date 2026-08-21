# frozen_string_literal: true

class CreateRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_press_kits, id: :uuid do |t|
      t.string :title, null: false
      t.datetime :created_at, null: false
    end
  end
end
