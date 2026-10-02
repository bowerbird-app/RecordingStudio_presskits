# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteSection
    class Upload
      def initialize(view, section_recording, quote_recording)
        @view = view
        @section_recording = section_recording
        @quote_recording = quote_recording
      end

      def data
        { controller: "recording-studio-attachable--upload" }.merge(limits).merge(urls)
      end

      private

      def limits
        {
          recording_studio_attachable__upload_max_file_size_value: max_file_size,
          recording_studio_attachable__upload_max_files_count_value: max_file_count,
          recording_studio_attachable__upload_allowed_content_types_value: allowed_content_types
        }
      end

      def urls
        {
          recording_studio_attachable__upload_direct_upload_url_value: direct_upload_url,
          recording_studio_attachable__upload_finalize_url_value: finalize_url,
          recording_studio_attachable__upload_remove_button_template_value: remove_button_template
        }
      end

      def direct_upload_url
        view.main_app.rails_direct_uploads_path
      end

      def finalize_url
        view.recording_studio_attachable.recording_attachment_imports_path(
          quote_recording,
          redirect_mode: "return_to",
          return_to: section_path
        )
      end

      def section_path
        view.edit_press_kit_section_path(section_recording.parent_recording, section_recording)
      end

      def remove_button_template
        String.new(view.tag.button("Remove", type: "button", data: remove_button_data))
      end

      def remove_button_data
        { action: "recording-studio-attachable--upload#remove", id: "__ENTRY_ID__" }
      end

      def max_file_size
        attachable_options[:max_file_size]
      end

      def max_file_count
        attachable_options[:max_file_count]
      end

      def allowed_content_types
        Array(attachable_options[:allowed_content_types]).join(",")
      end

      def attachable_options
        RecordingStudio.capability_options(:attachable, for: Quote).to_h
      end

      attr_reader :view, :section_recording, :quote_recording
    end
  end
end
