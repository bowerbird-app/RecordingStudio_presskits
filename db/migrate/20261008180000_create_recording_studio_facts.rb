# frozen_string_literal: true

class CreateRecordingStudioFacts < ActiveRecord::Migration[8.1]
  def change
    create_facts_sections
    create_facts
  end

  private

  def create_facts_sections
    create_table :recording_studio_facts_sections, id: :uuid do |t|
      t.string :display_style, null: false, default: "list"
      t.integer :columns, null: false, default: 3
      t.datetime :created_at, null: false
    end
  end

  def create_facts
    create_table :recording_studio_facts, id: :uuid do |t|
      t.string :label, null: false, default: ""
      t.text :value, null: false, default: ""
      t.string :unit
      t.text :description
      t.string :source_url
      t.date :as_of_date
      t.datetime :created_at, null: false
    end
  end
end
