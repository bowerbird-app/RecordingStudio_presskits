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
          preview: :natural
        }
      end

      def upload_form_data(view)
        {
          controller: "recording-studio-attachable--upload",
          recording_studio_attachable__upload_direct_upload_url_value: view.main_app.rails_direct_uploads_path,
          recording_studio_attachable__upload_finalize_url_value: upload_url_for(view),
          recording_studio_attachable__upload_max_file_size_value: max_file_size,
          recording_studio_attachable__upload_max_files_count_value: max_file_count,
          recording_studio_attachable__upload_allowed_content_types_value: allowed_content_types,
          recording_studio_attachable__upload_remove_button_template_value: remove_button_template(view)
        }
      end

      def upload_url_for(view)
        view.recording_studio_attachable.recording_attachment_imports_path(
          @recording,
          redirect_mode: "return_to",
          return_to: view.edit_press_kit_section_path(press_kit_recording, kit_section_recording)
        )
      end

      def kit_section_recording
        @recording.parent_recording
      end

      def press_kit_recording
        kit_section_recording.parent_recording
      end

      def capability_options
        RecordingStudio.capability_options(:attachable, for: RecordingStudioPresskits::Images).to_h
      end

      def max_file_size
        capability_options[:max_file_size]
      end

      def max_file_count
        capability_options[:max_file_count]
      end

      def allowed_content_types
        Array(capability_options[:allowed_content_types]).join(",")
      end

      def remove_button_template(view)
        button = view.tag.button(
          "Remove",
          type: "button",
          data: { action: "recording-studio-attachable--upload#remove", id: "__ENTRY_ID__" }
        )
        String.new(button)
      end
    end
  end
end
