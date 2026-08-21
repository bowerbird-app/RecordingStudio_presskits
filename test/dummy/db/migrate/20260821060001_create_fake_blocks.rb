# frozen_string_literal: true

class CreateFakeBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :fake_blocks, id: :uuid do |t|
      t.string :title, null: false
      t.datetime :created_at, null: false
    end
  end
end
