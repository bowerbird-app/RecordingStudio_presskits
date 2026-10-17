# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ItemActionRegistration
      private

      def location_set_registration
        action_registration(
          capability: :location,
          handler: LocationActions::Set,
          input_contract: location_input,
          summary: "Add a place to this section"
        )
      end

      def location_update_registration
        action_registration(
          capability: :location,
          handler: LocationActions::Update,
          input_contract: location_input(location_id: true),
          summary: "Update a place in this section"
        )
      end

      def location_clear_registration
        action_registration(
          capability: :trashable,
          handler: LocationActions::Clear,
          input_contract: id_input(:location_id),
          summary: "Remove a place from this section",
          required_role: :admin
        )
      end

      def location_input(location_id: false)
        fields = place_fields
        fields[:location_id] = { type: :string, required: true, allow_blank: false } if location_id
        { reject_unknown: true, fields: fields }
      end

      def place_fields
        RecordingStudio::Location::Location::PERMITTED_ATTRIBUTES.index_with do |name|
          place_field(name)
        end
      end

      def place_field(name)
        type = %i[latitude longitude].include?(name) ? :float : :string
        { type: type, required: false, allow_blank: true }
      end
    end
  end
end
