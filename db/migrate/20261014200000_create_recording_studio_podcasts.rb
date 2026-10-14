# frozen_string_literal: true

class CreateRecordingStudioPodcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_podcast_sections, id: :uuid do |t|
      t.datetime :created_at, null: false
    end

    create_table :recording_studio_podcasts, id: :uuid do |t|
      t.text :url, null: false
      t.text :title
      t.text :show_name
      t.date :aired_on
      t.string :duration
      t.text :artwork_source_url
      t.datetime :created_at, null: false
    end
  end
end
