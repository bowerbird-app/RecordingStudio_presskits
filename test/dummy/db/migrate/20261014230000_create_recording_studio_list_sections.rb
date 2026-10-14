# frozen_string_literal: true

class CreateRecordingStudioListSections < ActiveRecord::Migration[8.1]
  def change
    create_list_sections
    create_list_items
  end

  private

  def create_list_sections
    create_table :recording_studio_list_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def create_list_items
    create_table :recording_studio_kit_list_items, id: :uuid do |t|
      t.string :icon
      t.string :key, null: false, default: ""
      t.text :value, null: false, default: ""
      t.datetime :created_at, null: false
    end
  end
end
