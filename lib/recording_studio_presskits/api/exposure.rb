# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    # Serializers and MCP read the same payloads. An active embargo strips
    # protected fields unless the caller may edit the kit or has early access.
    module Exposure
      module_function

      def withhold?(context, recording)
        return false if context.nil? || recording.blank?

        Embargo.withhold_protected?(recording: recording, actor: actor_for(context))
      end

      def actor_for(context)
        grant = context.respond_to?(:access_grant) ? context.access_grant : nil
        return if grant.blank?
        return grant.actor if grant.respond_to?(:actor)

        nil
      end
    end
  end
end
