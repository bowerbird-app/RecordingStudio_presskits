# frozen_string_literal: true

module RecordingStudioPresskits
  class Quote
    class EditComponent < ViewComponent::Base
      def initialize(quote_recording:, section_recording:)
        super()
        @quote_recording = quote_recording
        @section_recording = section_recording
      end

      def quote
        @quote_recording.recordable
      end

      def update_path
        helpers.press_kit_section_quote_path(kit_recording, @section_recording, @quote_recording)
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      def image_path
        helpers.press_kit_section_quote_image_path(kit_recording, @section_recording, @quote_recording)
      end

      def upload_data
        QuoteSection::Upload.new(helpers, @section_recording, @quote_recording).data
      end

      def avatar_url
        file = avatar_file
        return unless file&.attached?

        helpers.main_app.url_for(file)
      end

      def avatar_alt
        quote.name.to_s.strip.presence || "Quote"
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end

      def avatar_file
        @quote_recording.images(per_page: 1).first&.recordable&.file
      end
    end
  end
end
