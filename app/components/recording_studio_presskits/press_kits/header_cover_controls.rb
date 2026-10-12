# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderCoverControls
      def initialize(helpers, press_kit_recording)
        @helpers = helpers
        @press_kit_recording = press_kit_recording
      end

      def cover_image_enabled?
        CoverImage.enabled?(@press_kit_recording) && @helpers.respond_to?(:recording_studio_attachable)
      end

      def cover_image_label
        I18n.t("recording_studio_presskits.editor.cover_image")
      end

      def cover_file_button_locals
        RecordingStudioAttachable::AttachmentFileButton.locals(
          recording: @press_kit_recording,
          return_to: cover_image_path,
          target: cover_turbo_frame,
          add_label: cover_image_action,
          change_label: cover_image_change
        )
      end

      def cover_attachment_recording
        CoverImage.resolved(@press_kit_recording)
      end

      def cover_remove_path
        @helpers.recording_studio_attachable.destroy_attachment_path(
          cover_attachment_recording,
          redirect_mode: "return_to",
          return_to: cover_image_path
        )
      end

      def cover_remove_data
        data = { turbo_method: :delete }
        data[:turbo_frame] = @helpers.presskits_editor_screen_id if @helpers.presskits_editor_dialog?
        data
      end

      private

      def cover_image_path
        @helpers.edit_press_kit_header_path(@press_kit_recording)
      end

      def cover_image_action
        I18n.t("recording_studio_presskits.editor.upload_cover_image")
      end

      def cover_image_change
        I18n.t("recording_studio_presskits.editor.change_cover_image")
      end

      def cover_turbo_frame
        @helpers.presskits_editor_screen_id if @helpers.presskits_editor_dialog?
      end
    end
  end
end
