# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :quote_section
        end

        def permitted_attributes
          []
        end

        def preview?
          false
        end

        def form?
          false
        end
      end

      def quotes
        @recording.recording_studio_orderable_children.reject { |child| hidden_quote?(child) }
      end

      def add_path
        helpers.press_kit_section_quotes_path(kit_recording, @recording)
      end

      def cancel_path
        helpers.edit_press_kit_path(kit_recording)
      end

      def order_path
        helpers.press_kit_section_quote_order_path(kit_recording, @recording)
      end

      def quote_path(quote_recording)
        helpers.press_kit_section_quote_path(kit_recording, @recording, quote_recording)
      end

      def image_path(quote_recording)
        helpers.press_kit_section_quote_image_path(kit_recording, @recording, quote_recording)
      end

      def upload_data_for(quote_recording)
        Upload.new(helpers, @recording, quote_recording).data
      end

      def avatar_url(quote_recording)
        file = avatar_file(quote_recording)
        return unless file&.attached?

        helpers.main_app.url_for(file)
      end

      def avatar_alt(quote_recording)
        quote_recording.recordable.name.to_s.strip.presence || "Quote"
      end

      private

      def hidden_quote?(child)
        child.trashed_at.present? || !child.recordable.is_a?(Quote)
      end

      def kit_recording
        @recording.parent_recording
      end

      def avatar_file(quote_recording)
        avatar_recording(quote_recording)&.recordable&.file
      end

      def avatar_recording(quote_recording)
        quote_recording.images(per_page: 1).first
      end
    end
  end
end
