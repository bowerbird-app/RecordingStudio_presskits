# frozen_string_literal: true

class CreateRecordingStudioPresskitsKitSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_presskits_kit_settings, id: :uuid do |t|
      t.uuid :recording_id, null: false
      t.string :visibility_fallback, null: false, default: "preview"
      t.timestamps
    end

    add_index :recording_studio_presskits_kit_settings, :recording_id,
              unique: true,
              name: "index_presskits_kit_settings_on_recording_id"
  end
end
