# frozen_string_literal: true

class ReplaceImagesCaptionWithTitleAndSubtitle < ActiveRecord::Migration[8.1]
  def up
    add_column :recording_studio_images, :title, :text
    add_column :recording_studio_images, :subtitle, :text
    execute <<~SQL.squish
      UPDATE recording_studio_images
      SET title = NULLIF(BTRIM(caption), '')
      WHERE caption IS NOT NULL
    SQL
    remove_column :recording_studio_images, :caption
  end

  def down
    add_column :recording_studio_images, :caption, :text
    execute <<~SQL.squish
      UPDATE recording_studio_images
      SET caption = NULLIF(BTRIM(title), '')
      WHERE title IS NOT NULL
    SQL
    remove_column :recording_studio_images, :title
    remove_column :recording_studio_images, :subtitle
  end
end
