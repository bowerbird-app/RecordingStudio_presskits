# frozen_string_literal: true

class AddIconToRecordingStudioCreditLines < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_credit_lines, :icon, :string
  end
end
