# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module SectionActionRegistration
      def register_section_actions
        register_section_action(:create_section, create_section_registration)
        register_section_action(:reorder_sections, reorder_sections_registration)
        register_section_action(:remove_section, remove_section_registration)
      end

      private

      def register_section_action(name, registration)
        return if ::RecordingStudioApi.capability_action(name)

        ::RecordingStudioApi.register_capability_action(name, **registration)
      end

      def create_section_registration
        action_registration(
          capability: :orderable,
          handler: CreateSection,
          input_contract: create_section_input,
          summary: "Create a section and its content"
        )
      end

      def reorder_sections_registration
        action_registration(
          capability: :orderable,
          handler: ReorderSections,
          input_contract: reorder_sections_input,
          summary: "Reorder kit sections"
        )
      end

      def remove_section_registration
        action_registration(
          capability: :trashable,
          handler: RemoveSection,
          input_contract: empty_action_input,
          summary: "Remove a kit section"
        )
      end

      def action_registration(capability:, handler:, input_contract:, summary:)
        {
          capability: capability,
          http_verb: :post,
          required_role: :edit,
          version: "1.0.0",
          handler: handler,
          input_contract: input_contract,
          openapi: { summary: summary }
        }
      end

      def create_section_input
        {
          reject_unknown: true,
          fields: {
            content_type: { type: :string, required: true, allow_blank: false },
            title: { type: :string, required: false, allow_blank: true },
            subtitle: { type: :string, required: false, allow_blank: true }
          }
        }
      end

      def reorder_sections_input
        {
          reject_unknown: true,
          fields: {
            ordered_recording_ids: { type: :array, required: true }
          }
        }
      end

      def empty_action_input
        { reject_unknown: true, fields: {} }
      end
    end
  end
end
