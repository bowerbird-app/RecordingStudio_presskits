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

      def upload_path
        helpers.recording_studio_attachable.recording_attachment_imports_path(
          @recording,
          redirect_mode: "return_to",
          return_to: return_path
        )
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
