# frozen_string_literal: true

class CreateRecordingStudioFacts < ActiveRecord::Migration[8.1]
  def change
    create_stats_sections
    create_stats
  end

  private

  def create_stats_sections
    create_table :recording_studio_stats_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def create_stats
    create_table :recording_studio_stats, id: :uuid do |t|
      t.string :label, null: false, default: ""
      t.text :value, null: false, default: ""
      t.string :unit
      t.text :description
      t.string :icon
      t.datetime :created_at, null: false
    end
  end
end
