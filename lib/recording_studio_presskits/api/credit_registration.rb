# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module CreditRegistration
      def register_credits!
        register_credit
        register_credit_line
        register_credits_section
        register_credit_actions
      end

      private

      def register_credit
        register_type(
          "RecordingStudioPresskits::Credit",
          operations: %i[index show create update destroy],
          serializer: CreditPayload.method(:for),
          output_keys: %i[name url usual_role],
          writable_attributes: %i[name url usual_role]
        )
      end

      def register_credit_line
        register_type(
          "RecordingStudioPresskits::CreditLine",
          operations: %i[index show create update destroy],
          serializer: CreditLinePayload.method(:for_api),
          output_keys: %i[role name url credit_id icon],
          writable_attributes: %i[role icon],
          capability_actions: %i[remove_credit]
        )
      end

      def register_credits_section
        register_type(
          "RecordingStudioPresskits::CreditsSection",
          **empty_section_options,
          capability_actions: %i[add_credit reorder_credits],
          relationships: { credit_lines: credit_lines_relationship }
        )
      end

      def credit_lines_relationship
        child_collection(
          "RecordingStudioPresskits::CreditLine",
          serializer: CreditLinePayload.method(:for_api),
          output_keys: %i[role name url credit_id icon],
          endpoints: %i[index show create update destroy],
          description: "Credit lines in this section"
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
          summary: "Add a workspace credit to this section"
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
          summary: "Remove a credit from this section",
          required_role: :admin
        )
      end

      def add_credit_input
        {
          reject_unknown: true,
          fields: {
            credit_id: { type: :string, required: true, allow_blank: false },
            role: { type: :string, required: false, allow_blank: true },
            icon: { type: :string, required: false, allow_blank: true }
          }
        }
      end
    end
  end
end
