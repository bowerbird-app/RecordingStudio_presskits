# frozen_string_literal: true

module RecordingStudioPresskits
  # One resolver for who sees a kit. Controllers, views, listings, cards, and
  # meta tags call this. Do not scatter audience or fallback checks.
  #
  # Returns :full, :preview, :hidden, or :unavailable. Hidden and unavailable
  # both 404 for visitors. Unavailable is "this is not live"; hidden is "it is
  # live but we will not confirm it". A later embargo can swap the policy
  # without changing this order: published? → kit_view_full → fallback.
  class Visibility
    ACTION = :"presskits.kit_view_full"
    FALLBACKS = %i[preview hidden].freeze
    PRESENTATIONS = %i[full preview hidden unavailable].freeze
    DEFAULT_ACTION_AUDIENCES = {
      allowed: %i[public signed_in granted],
      default: :public,
      granted_roles: %i[view edit admin],
      granted_override: false,
      manage_role: :edit
    }.freeze
    PRIVATE_CACHE = "private, no-store"

    class << self
      def register_action!
        return unless defined?(RecordingStudioAccessible)
        return unless RecordingStudioAccessible.configuration.respond_to?(:action_audiences)
        return if RecordingStudioAccessible.configuration.action_audiences.configured?(ACTION)

        RecordingStudioAccessible.configuration.action_audiences[ACTION] = DEFAULT_ACTION_AUDIENCES.dup
      end

      def presentation_for(actor:, kit:, purpose: :public)
        recording = recording_for(kit)
        return :unavailable if recording.blank?

        unless published?(recording)
          return :full if purpose.to_sym == :editor && editor?(actor, recording)

          return :unavailable
        end

        return :full if authorized_full?(actor, recording)

        policy_for(recording).fetch(:fallback)
      end

      def discoverable?(actor:, kit:)
        %i[full preview].include?(presentation_for(actor: actor, kit: kit, purpose: :public))
      end

      def apply_public_response!(presentation:, response:)
        resolved = normalize_presentation(presentation)
        response.set_header("Cache-Control", PRIVATE_CACHE) unless resolved == :full
        # Publishable renders this page through RendersPublicPage: the inner
        # controller response is discarded, and a RoutingError during view
        # render is rebuilt by the exceptions app (losing Cache-Control).
        # Set 404 on the live response and skip kit HTML instead.
        response.status = 404 unless %i[full preview].include?(resolved)
        resolved
      end

      def fragment_cache_key(kit, presentation)
        recording = recording_for(kit)
        ["presskits", recording&.id, normalize_presentation(presentation), recording&.recordable_id]
      end

      def audience_options_for(recording)
        return [] unless defined?(RecordingStudioAccessible)

        RecordingStudioAccessible.audience_options_for(recording: recording, action: ACTION)
      end

      def effective_audience(recording)
        return :denied unless defined?(RecordingStudioAccessible)

        RecordingStudioAccessible.effective_audience(recording: recording, action: ACTION)
      end

      def set_audience!(recording:, audience:, actor:)
        RecordingStudioAccessible.set_audience!(
          recording: recording,
          action: ACTION,
          audience: audience,
          actor: actor
        )
      end

      def authorized_full?(actor, recording)
        return false unless defined?(RecordingStudioAccessible)
        return false if recording.blank?

        RecordingStudioAccessible.authorized_action?(
          actor: actor,
          action: ACTION,
          recording: recording
        )
      end

      def sign_in_path
        RecordingStudioPresskits.configuration.sign_in_path.presence || "/users/sign_in"
      end

      def preview_reason_for(recording)
        audience = effective_audience(recording)
        audience == :signed_in ? :signed_in : :granted
      end

      private

      def policy_for(recording)
        {
          fallback: KitSettings.fallback_for(recording)
        }
      end

      def published?(recording)
        recording.respond_to?(:currently_published?) && recording.currently_published?
      end

      def editor?(actor, recording)
        return false unless defined?(RecordingStudioAccessible)
        return false if actor.blank? || recording.blank?

        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)
      end

      def recording_for(kit)
        return kit if kit.respond_to?(:recordable_type)
        return kit.recording if kit.respond_to?(:recording)

        kit
      end

      def normalize_presentation(presentation)
        name = presentation.to_s.to_sym
        PRESENTATIONS.include?(name) ? name : :unavailable
      end
    end
  end
end
