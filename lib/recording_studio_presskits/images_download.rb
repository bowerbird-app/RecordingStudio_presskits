# frozen_string_literal: true

module RecordingStudioPresskits
  # Section photo zips. Separate from the kit zip so each images recording
  # keeps its own package. The audience stays public; who can see the full
  # kit is `downloadable_available_for?` on Images.
  class ImagesDownload
    ACTION = :"presskits.images_download"
    EXPORT_SCOPE = :public

    class << self
      def audience_defaults
        {
          allowed: default_allowed_audiences,
          default: :public,
          granted_roles: %i[view edit admin],
          granted_override: true,
          manage_role: :edit
        }
      end

      def configure_audience!
        return unless defined?(RecordingStudioAccessible)
        return unless RecordingStudioAccessible.configuration.respond_to?(:action_audiences)

        audiences = RecordingStudioAccessible.configuration.action_audiences
        return if audiences.configured?(ACTION)

        audiences[ACTION] = audience_defaults
      end

      private

      def default_allowed_audiences
        names = %i[public signed_in granted]
        return names unless defined?(RecordingStudioAccessible)

        names | RecordingStudioAccessible.audience_registry.names
      end
    end
  end
end
