# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    # Serializers and MCP read the same payloads. An active embargo strips
    # protected fields unless the caller may edit the kit or has early access.
    module Exposure
      module_function

      def withhold?(context, recording)
        return false if context.nil? || recording.blank?

        actor = actor_for(context)
        return true if Embargo.withhold_protected?(recording: recording, actor: actor)
        return false unless access_grant?(context)

        kit = Embargo.kit_recording(recording)
        return false if kit.blank?
        return false if Visibility.edits?(actor, kit)

        Visibility.presentation_for(actor: actor, kit: kit, purpose: :public) != :full
      end

      def actor_for(context)
        grant = context.respond_to?(:access_grant) ? context.access_grant : nil
        return if grant.blank?
        return grant.actor if grant.respond_to?(:actor)

        nil
      end

      # Callers pass the section as `recording:`. The Recording Studio API
      # passes it on `context` instead. Prefer the explicit recording.
      def named_recording(recording: nil, context: nil, recordable: nil)
        return recording if recording.present?

        current = recording_on(context, :recording)
        target = recording_on(context, :target_recording)
        if recordable
          return target if same_recordable?(target, recordable)
          return current if same_recordable?(current, recordable)
        end

        current || target
      end

      def access_grant?(context)
        context.respond_to?(:access_grant) && context.access_grant.present?
      end

      def recording_on(context, name)
        return unless context.respond_to?(name)

        context.public_send(name)
      end

      def same_recordable?(recording, recordable)
        recording.present? && recording.recordable == recordable
      end
    end
  end
end
