# frozen_string_literal: true

class CreateRecordingStudioMenuSections < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_menu_sections, id: :uuid do |t|
      t.string :layout, null: false, default: "grid"
      t.boolean :show_counts, null: false, default: true
      t.boolean :show_icons, null: false, default: true
      t.json :items, null: false, default: {}
      t.datetime :created_at, null: false
    end
  end
end
