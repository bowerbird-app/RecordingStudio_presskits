# frozen_string_literal: true

class AddCoverToRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_press_kits, :cover_style, :string
    add_column :recording_studio_press_kits, :cover_color, :string
  end
end
