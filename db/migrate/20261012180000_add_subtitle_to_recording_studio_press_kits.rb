# frozen_string_literal: true

class AddSubtitleToRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_press_kits, :subtitle, :string
  end
end
