# frozen_string_literal: true

class CreateShowcases < ActiveRecord::Migration[8.1]
  def change
    create_table :showcases, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
