# frozen_string_literal: true

class ReplacePressKitCoverWithBrand < ActiveRecord::Migration[8.1]
  def change
    remove_column :recording_studio_press_kits, :cover_style, :string
    remove_column :recording_studio_press_kits, :cover_color, :string
    remove_column :recording_studio_press_kits, :cover_text_color, :string
    add_column :recording_studio_press_kits, :brand_color, :string
    add_column :recording_studio_press_kits, :font_family, :string
  end
end
