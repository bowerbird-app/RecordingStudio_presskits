# frozen_string_literal: true

module RecordingStudioPresskits
  class Visibility
    module Caching
      def apply_public_response!(presentation:, response:, kit: nil)
        resolved = normalize_presentation(presentation)
        response.set_header("Cache-Control", Visibility::PRIVATE_CACHE) if private_response?(resolved, kit)
        # Publishable renders this page through RendersPublicPage: the inner
        # controller response is discarded, and a RoutingError during view
        # render is rebuilt by the exceptions app (losing Cache-Control).
        # Set 404 on the live response and skip kit HTML instead.
        response.status = 404 unless %i[full preview].include?(resolved)
        resolved
      end

      def fragment_cache_key(kit, presentation, actor: nil)
        recording = recording_for(kit)
        key = ["presskits", recording&.id, normalize_presentation(presentation), recording&.recordable_id]
        return key unless Embargo.active?(recording)

        key + ["embargo", Embargo.cache_boundary(recording), actor_cache_token(actor)]
      end

      private

      def private_response?(presentation, kit)
        return true unless presentation == :full

        Embargo.active?(recording_for(kit))
      end

      def actor_cache_token(actor)
        return "anonymous" if actor.blank?
        return actor.id.to_s if actor.respond_to?(:id) && actor.id.present?

        actor.object_id.to_s
      end
    end
  end
end
