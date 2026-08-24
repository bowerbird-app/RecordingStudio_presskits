# frozen_string_literal: true

module RecordingStudioPresskits
  module ApplicationHelper
    def presskits_page_nav(title:, back_url: nil, back_label: "Go back", close_url: nil)
      recording_studio_page_nav(
        title: title,
        page_nav_back_url: back_url,
        page_nav_back_label: back_label,
        page_nav_anchor_url: close_url
      )
      fill_presskits_page_nav_right
    end

    def fill_presskits_page_nav_right
      recording = presskits_access_recording
      return unless recording
      return unless respond_to?(:recording_studio_accessible_avatars)

      recording_studio_page_nav_right do
        concat recording_studio_accessible_avatars(recording, button_style: :ghost, button_size: :md)
      end
    end

    def presskits_access_recording
      return current_presskits_root if respond_to?(:current_presskits_root) && current_presskits_root.present?
      return current_root_recording if respond_to?(:current_root_recording) && current_root_recording.present?

      nil
    end

    def presskits_title_for(recording)
      recording.recordable&.try(:title).presence || recording.name.presence || recording.type_label
    end

    def presskits_index_path(view: nil)
      view.present? ? press_kits_path(view: view) : press_kits_path
    end

    def presskits_public_path_for(recording)
      return unless recording.respond_to?(:publishable_public_path)

      recording.publishable_public_path
    end

    def presskits_publish_path_for(recording)
      return if recording.blank?

      engine = presskits_publishable_engine
      return unless engine.respond_to?(:edit_recording_publishable_path)

      engine.edit_recording_publishable_path(recording_id: recording.id)
    rescue StandardError
      nil
    end

    def recording_studio_publishable
      presskits_publishable_engine
    end

    def presskits_publishable_engine
      return RecordingStudioPublishable::Engine.routes.url_helpers if defined?(RecordingStudioPublishable::Engine)

      nil
    end
  end
end
