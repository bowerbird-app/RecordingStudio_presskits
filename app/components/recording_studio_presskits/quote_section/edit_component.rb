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

      def edit_path(quote_recording)
        helpers.edit_press_kit_section_quote_path(kit_recording, @recording, quote_recording)
      end

      def remove_path(quote_recording)
        helpers.press_kit_section_quote_path(kit_recording, @recording, quote_recording)
      end

      def row_label(quote_recording)
        quote = quote_recording.recordable
        quote.name.to_s.strip.presence || quote.body.to_s.strip.truncate(80).presence || "Quote"
      end

      private

      def hidden_quote?(child)
        child.trashed_at.present? || !child.recordable.is_a?(Quote)
      end

      def kit_recording
        @recording.parent_recording
      end
    end
  end
end
