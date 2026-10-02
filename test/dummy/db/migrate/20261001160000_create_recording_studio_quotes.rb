# frozen_string_literal: true

class CreateRecordingStudioQuotes < ActiveRecord::Migration[8.1]
  def change
    create_quote_sections
    create_quotes
  end

  private

  def create_quote_sections
    create_table :recording_studio_quote_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def create_quotes
    create_table :recording_studio_quotes, id: :uuid do |t|
      t.text :body, null: false, default: ""
      t.string :name, null: false, default: ""
      t.string :role
      t.string :organisation
      t.datetime :created_at, null: false
    end
  end
end
