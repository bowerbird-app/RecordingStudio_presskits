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
      recording_studio_page_nav_right do
        if respond_to?(:recording_studio_root_switch_dropdown)
          concat recording_studio_root_switch_dropdown(style: :ghost, size: :md)
        end
        concat presskits_extra_nav if respond_to?(:presskits_extra_nav)
      end
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

      engine.edit_recording_publishable_path(recording.id)
    rescue StandardError
      nil
    end

    def presskits_publishable_engine
      return recording_studio_publishable if respond_to?(:recording_studio_publishable)
      return main_app.recording_studio_publishable if respond_to?(:main_app) &&
                                                      main_app.respond_to?(:recording_studio_publishable)

      nil
    end
  end
end
