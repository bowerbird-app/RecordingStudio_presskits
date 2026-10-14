# frozen_string_literal: true

class AddReleaseDateToRecordingStudioPressKits < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_press_kits, :release_date, :date
  end
end
