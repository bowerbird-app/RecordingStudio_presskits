# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module CreditRegistration
      def register_credits!
        register_credit_line
        register_credits_section
        register_credit_actions
      end

      private

      def register_credit_line
        register_type(
          "RecordingStudioPresskits::CreditLine",
          operations: %i[index show update],
          serializer: credit_line_serializer,
          output_keys: %i[name role url],
          writable_attributes: %i[name role url],
          capability_actions: %i[remove_credit]
        )
      end

      def credit_line_serializer
        lambda { |recordable, recording: nil, **|
          recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
          CreditLinePayload.for(recording)
        }
      end

      def register_credits_section
        register_type(
          "RecordingStudioPresskits::CreditsSection",
          **empty_section_options,
          capability_actions: %i[add_credit reorder_credits]
        )
      end

      def register_credit_actions
        register_section_action(:add_credit, add_credit_registration)
        register_section_action(:reorder_credits, reorder_credits_registration)
        register_section_action(:remove_credit, remove_credit_registration)
      end

      def add_credit_registration
        action_registration(
          capability: :orderable,
          handler: AddCredit,
          input_contract: add_credit_input,
          summary: "Add a credit to this section"
        )
      end

      def reorder_credits_registration
        action_registration(
          capability: :orderable,
          handler: ReorderCredits,
          input_contract: reorder_sections_input,
          summary: "Reorder credits in this section"
        )
      end

      def remove_credit_registration
        action_registration(
          capability: :trashable,
          handler: RemoveCredit,
          input_contract: empty_action_input,
          summary: "Remove a credit from this section"
        )
      end

      def add_credit_input
        {
          reject_unknown: true,
          fields: {
            name: { type: :string, required: true, allow_blank: false },
            url: { type: :string, required: false, allow_blank: true },
            role: { type: :string, required: false, allow_blank: true }
          }
        }
      end
    end
  end
end
