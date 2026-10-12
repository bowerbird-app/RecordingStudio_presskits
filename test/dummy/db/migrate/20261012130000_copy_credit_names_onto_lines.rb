# frozen_string_literal: true

class CopyCreditNamesOntoLines < ActiveRecord::Migration[8.1]
  def up
    add_owned_columns
    change_column_null :recording_studio_credit_lines, :credit_recording_id, true
    create_hide_table
    RecordingStudioPresskits::CreditLine.reset_column_information
    RecordingStudioPresskits::CreditLineOwnership.migrate!
  end

  def down
    RecordingStudioPresskits::CreditLineOwnership.revert!
    change_column_null :recording_studio_credit_lines, :credit_recording_id, false
    remove_column :recording_studio_credit_lines, :name, if_exists: true
    remove_column :recording_studio_credit_lines, :url, if_exists: true
    drop_table :recording_studio_credit_line_library_hides, if_exists: true
    RecordingStudioPresskits::CreditLine.reset_column_information
  end

  private

  def add_owned_columns
    return if column_exists?(:recording_studio_credit_lines, :name)

    add_column :recording_studio_credit_lines, :name, :string
    add_column :recording_studio_credit_lines, :url, :string
  end

  def create_hide_table
    return if table_exists?(:recording_studio_credit_line_library_hides)

    create_table :recording_studio_credit_line_library_hides, id: :uuid do |t|
      t.uuid :line_recording_id, null: false
      t.datetime :created_at, null: false
      t.index :line_recording_id, unique: true, name: "index_credit_line_library_hides_on_line"
    end
  end
end
