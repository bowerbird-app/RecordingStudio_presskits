# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class PublicShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings: nil, preview: false)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @preview = preview
      end

      def section_recordings
        @section_recordings || KitQuery.sections_for(@press_kit_recording)
      end

      def visible_section_recordings
        section_recordings.select { |recording| section_visible?(recording) }
      end

      def preview?
        @preview
      end

      def live?
        @press_kit_recording.respond_to?(:currently_published?) && @press_kit_recording.currently_published?
      end

      def section_visible?(recording)
        SectionFrameComponent.new(section_recording: recording).content_visible?
      end

      def show_download?
        return false if preview?
        return false unless live?

        KitDownload.allowed?(@press_kit_recording, actor: download_actor)
      end

      def download_button_options
        {
          generate_text: I18n.t("recording_studio_presskits.download.button"),
          ready_text: I18n.t("recording_studio_presskits.download.button"),
          preparing_text: I18n.t("recording_studio_presskits.download.preparing"),
          retry_text: I18n.t("recording_studio_presskits.download.retry")
        }
      end

      private

      def download_actor
        if helpers.respond_to?(:current_user, true)
          return helpers.current_user
        end

        return Current.actor if defined?(Current) && Current.respond_to?(:actor) && Current.actor

        nil
      end
    end
  end
end
