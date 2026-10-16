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
          summary: "Remove a kit section",
          required_role: :admin
        )
      end

      def action_registration(capability:, handler:, input_contract:, summary:, required_role: :edit)
        {
          capability: capability,
          http_verb: :post,
          required_role: required_role,
          version: "1.0.0",
          handler: handler,
          input_contract: route_contract(input_contract),
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

      def route_contract(definition)
        return definition unless defined?(::RecordingStudioApi::ActionInputContract)

        RouteContracts.for(definition)
      end
    end

    # Member actions leave route defaults in the params hash. Recording Studio
    # API does not strip them before reject_unknown contracts.
    module RouteContracts
      ROUTE_KEYS = %i[api_key api_version member_action action action_name controller format id resource].freeze

      def self.for(definition)
        contract_class.new(definition)
      end

      def self.contract_class
        @contract_class ||= Class.new(::RecordingStudioApi::ActionInputContract) do
          def call(raw_params)
            params = raw_params.respond_to?(:to_unsafe_h) ? raw_params.to_unsafe_h : raw_params.to_h
            params = params.deep_symbolize_keys if params.respond_to?(:deep_symbolize_keys)
            super(params.except(*RouteContracts::ROUTE_KEYS))
          end
        end
      end
    end
  end
end
