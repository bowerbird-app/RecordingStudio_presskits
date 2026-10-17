# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    # Shared lookup, Accessible checks, and JSON shaping for resource handlers.
    module Gate
      module_function

      def actor(context)
        context.access_grant&.actor
      end

      def params_hash(context)
        raw = context.respond_to?(:params) ? context.params : {}
        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.respond_to?(:deep_symbolize_keys) ? hash.deep_symbolize_keys : {}
      end

      def param(context, name)
        params_hash(context)[name.to_sym]
      end

      def authorize!(context, recording, role)
        context.access_grant.authorize!(
          recording: recording,
          role: role,
          include_trashed: role.to_sym == :admin
        )
      end

      def ensure_readable!(context, recording)
        authorize!(context, recording, :view)
        return if audience_allows?(context, recording)

        not_found!
      end

      def audience_allows?(context, recording)
        kit = kit_for(recording)
        return true if kit.blank?

        reader = actor(context)
        return true if Visibility.edits?(reader, kit)

        presentation = Visibility.presentation_for(actor: reader, kit: kit, purpose: :public)
        %i[full preview].include?(presentation)
      end

      def kit_for(recording)
        return recording if press_kit?(recording)

        Embargo.kit_recording(recording)
      end

      def nested_parent(context)
        parent_id = context.parent_id.presence if context.respond_to?(:parent_id)
        parent_id ||= param(context, :parent_id)
        return if parent_id.blank?

        found = context.scoped_recordings.find_by(id: parent_id)
        not_found!("Parent resource was not found in this API scope") if found.nil?

        found
      end

      def parent!(context)
        return context.parent_recording if context.respond_to?(:parent_recording) && context.parent_recording.present?

        nested_parent(context) || not_found!("parent_id is required")
      end

      def find!(context)
        identifier = relationship_or_member_id(context)
        not_found! if identifier.blank?

        recording = context.scoped_recordings.find_by(id: identifier)
        not_found! if recording.nil? || recording.recordable_type != context.recordable_type

        recording
      end

      def writable(context)
        registration = ::RecordingStudioApi.recordable_registration_for(context.recordable_type, api: context.api_key)
        keys = Array(registration&.writable_attributes).map(&:to_sym)
        params_hash(context).slice(*keys)
      end

      def readable_ids(context, relation)
        relation.select { |recording| readable_recording?(context, recording) }.map(&:id)
      end

      def not_found!(message = "Resource was not found in this API scope")
        raise ::RecordingStudioApi::NotFoundError, message
      end

      def readable_recording?(context, recording)
        context.access_grant.authorized?(recording: recording, role: :view) &&
          audience_allows?(context, recording)
      end

      def relationship_or_member_id(context)
        return context.relationship_id if relationship_request?(context)
        return context.id if context.respond_to?(:id) && context.id.present?

        param(context, :id)
      end

      def relationship_request?(context)
        context.respond_to?(:relationship_id) && context.relationship_id.present?
      end

      def press_kit?(recording)
        recording.recordable_type.to_s == "RecordingStudioPresskits::PressKit"
      end
      private_class_method :readable_recording?, :relationship_or_member_id, :relationship_request?, :press_kit?
    end
  end
end
