# frozen_string_literal: true

class CreateRecordingStudioCredits < ActiveRecord::Migration[8.1]
  def change
    create_credits_sections
    create_credits
    create_credit_lines
  end

  private

  def create_credits_sections
    create_table :recording_studio_credits_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def create_credits
    create_table :recording_studio_credits, id: :uuid do |t|
      t.string :name, null: false
      t.string :url
      t.string :usual_role
      t.datetime :created_at, null: false
    end
  end

  def create_credit_lines
    create_table :recording_studio_credit_lines, id: :uuid do |t|
      t.uuid :credit_recording_id, null: false
      t.string :role
      t.datetime :created_at, null: false
      t.index :credit_recording_id
    end
  end
end
