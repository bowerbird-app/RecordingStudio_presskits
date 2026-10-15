# frozen_string_literal: true

class AddTextColorAndCornerStyleToRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_press_kits, :text_color, :string
    add_column :recording_studio_press_kits, :corner_style, :string
  end
end
