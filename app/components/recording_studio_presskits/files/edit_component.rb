# frozen_string_literal: true

module RecordingStudioPresskits
  class Files
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      def self.param_key
        :files
      end

      def self.permitted_attributes
        []
      end

      def self.below?
        true
      end

      def upload_button_locals
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

      def collection
        @collection ||= RecordingStudioAttachable::AttachmentCollection.for(
          recording: @recording,
          association: :files,
          fields: %i[name description],
          sortable: true,
          displays: [:list],
          empty_message: "No files yet."
        )
      end

      def save_path
        helpers.attachable_attachment_collection_path(@recording)
      end

      def remove_path(row)
        helpers.attachment_collection_remove_path(collection, row, return_to: return_path)
      end

      def presentation_for(row)
        FilePresentation.new(row.recording.recordable)
      end

      def redirect_fields
        RecordingStudioAttachable::AttachmentFileButton.redirect_params(return_to: return_path)
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
