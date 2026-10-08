# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :credits_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def batch
        @batch ||= CreditLineBatch.for_section(@recording)
      end

      def blank_line
        CreditLineBatch.blank_draft
      end

      def lines_path
        helpers.press_kit_section_credit_lines_path(kit_recording, kit_section_recording)
      end

      def order_path
        helpers.press_kit_section_credit_order_path(kit_recording, kit_section_recording)
      end

      def search_path
        helpers.search_credits_path
      end

      def credits_path
        helpers.credits_path
      end

      def preview_actions
        %w[
          list:saved->recording-studio-presskits--credit-preview#sync
          list:reordered->recording-studio-presskits--credit-preview#sync
          collection-editor:selected->recording-studio-presskits--credit-preview#choose
          input->recording-studio-presskits--credit-preview#role
          click->recording-studio-presskits--credit-preview#drop
        ].join(" ")
      end

      def credit_catalog_json
        ERB::Util.json_escape(credit_catalog.to_json)
      end

      private

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end

      def credit_catalog
        Credits.active_for_root(@recording.root_recording).each_with_object({}) do |recording, catalog|
          catalog[recording.id] = sanitized_credit_url(recording)
        end
      end

      def sanitized_credit_url(recording)
        FlatPack::AttributeSanitizer.sanitize_url(recording.recordable&.url).to_s
      end
    end
  end
end
