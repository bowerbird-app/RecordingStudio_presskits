# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    class EditComponent < ViewComponent::Base
      include Gallery

      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @images = recording.recordable
        @update_path = update_path
      end

      def self.param_key
        :images
      end

      def self.permitted_attributes
        [:caption]
      end

      def self.preview?
        false
      end

      def image_recordings
        gallery_images_for(@recording)
      end

      def image_url_for(attachment_recording)
        gallery_image_url(attachment_recording)
      end

      def upload_url
        helpers.recording_studio_attachable.recording_attachment_imports_path(
          @recording,
          redirect_mode: "return_to",
          return_to: return_path
        )
      end

      def direct_upload_url
        helpers.main_app.rails_direct_uploads_path
      end

      def return_path
        helpers.edit_press_kit_section_path(@recording.parent_recording, @recording)
      end

      def remove_path_for(image_recording)
        helpers.press_kit_section_image_path(@recording.parent_recording, @recording, image_recording)
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

      def remove_button_template
        button = helpers.tag.button(
          "Remove",
          type: "button",
          data: { action: "recording-studio-attachable--upload#remove", id: "__ENTRY_ID__" }
        )
        String.new(button)
      end
    end
  end
end
