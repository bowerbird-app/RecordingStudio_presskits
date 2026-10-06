# frozen_string_literal: true

class AddTitleToRecordingStudioTexts < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_texts, :title, :text
  end
end
