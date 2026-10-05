# frozen_string_literal: true

class AddDescriptionToRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_press_kits, :description, :text
  end
end
