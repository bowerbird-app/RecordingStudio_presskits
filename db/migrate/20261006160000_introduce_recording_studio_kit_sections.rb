# frozen_string_literal: true

class IntroduceRecordingStudioKitSections < ActiveRecord::Migration[8.1]
  def up
    create_table :recording_studio_kit_sections, id: :uuid do |t|
      t.text :title
      t.text :subtitle
      t.datetime :created_at, null: false
    end

    RecordingStudioPresskits::LegacySectionTree.migrate!

    remove_column :recording_studio_texts, :title if column_exists?(:recording_studio_texts, :title)
    return unless column_exists?(:recording_studio_images, :title)

    remove_column :recording_studio_images, :title
    remove_column :recording_studio_images, :subtitle
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
