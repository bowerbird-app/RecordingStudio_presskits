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
          true
        end

        def form?
          false
        end
      end

      def quotes
        @recording.recording_studio_orderable_children.reject { |child| hidden_quote?(child) }
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def order_path
        helpers.press_kit_section_quote_order_path(kit_recording, kit_section_recording)
      end

      def edit_path(quote_recording)
        helpers.edit_press_kit_section_quote_path(kit_recording, kit_section_recording, quote_recording)
      end

      def remove_path(quote_recording)
        helpers.press_kit_section_quote_path(kit_recording, kit_section_recording, quote_recording)
      end

      def quote_snippet(quote_recording)
        quote_recording.recordable.body.to_s.strip.presence || "Quote"
      end

      def quote_name(quote_recording)
        quote_recording.recordable.name.to_s.strip.presence
      end

      private

      def hidden_quote?(child)
        child.trashed_at.present? || !child.recordable.is_a?(Quote)
      end

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
