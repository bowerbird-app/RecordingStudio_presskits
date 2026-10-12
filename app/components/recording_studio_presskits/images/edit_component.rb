# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      def self.param_key
        :images
      end

      def self.permitted_attributes
        []
      end

      def self.below?
        true
      end

      def attachment_collection_options
        {
          association: :images,
          fields: %i[caption credit alt_text],
          sortable: true,
          displays: %i[list carousel grid],
          default_display: :list,
          preview: :natural,
          empty_message: "No images yet."
        }
      end

      def upload_button_locals
        # The file button replaces its one attachment once a file exists.
        # An Images section keeps importing another file.
        RecordingStudioAttachable::AttachmentFileButton.locals(
          recording: @recording,
          return_to: return_path,
          target: upload_turbo_frame,
          add_label: "Upload"
        ).merge(attachment_recording: nil)
      end

      def upload_turbo_frame
        helpers.presskits_editor_screen_id if helpers.presskits_editor_dialog?
      end

      def return_path
        helpers.edit_press_kit_section_path(press_kit_recording, kit_section_recording)
      end

      def kit_section_recording
        @recording.parent_recording
      end

      def press_kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
