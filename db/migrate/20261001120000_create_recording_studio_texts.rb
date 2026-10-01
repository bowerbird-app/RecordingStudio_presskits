# frozen_string_literal: true

class CreateRecordingStudioTexts < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_texts, id: :uuid do |t|
      t.text :body, null: false
      t.datetime :created_at, null: false
    end
  end
end
