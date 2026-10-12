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

      def preview_actions
        %w[
          list:saved->recording-studio-presskits--credit-preview#sync
          list:reordered->recording-studio-presskits--credit-preview#sync
          input->recording-studio-presskits--credit-preview#fields
          click->recording-studio-presskits--credit-preview#drop
          click->recording-studio-presskits--credit-preview#note
        ].join(" ")
      end

      private

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
