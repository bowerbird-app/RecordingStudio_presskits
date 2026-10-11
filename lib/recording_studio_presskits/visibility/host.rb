# frozen_string_literal: true

module RecordingStudioPresskits
  class Visibility
    # Host paths and the site name on limited previews.
    class Host
      class << self
        def sign_in_path
          RecordingStudioPresskits.configuration.sign_in_path.presence || "/users/sign_in"
        end

        def registration_path
          RecordingStudioPresskits.configuration.registration_path.to_s.strip.presence
        end

        def site_name
          configured = RecordingStudioPresskits.configuration.site_name.to_s.strip.presence
          return configured if configured.present?

          translated = I18n.t("recording_studio_presskits.visibility.site_name", default: "").to_s.strip
          return translated if translated.present?

          rails_application_name
        end

        def rails_application_name
          fallback = I18n.t("recording_studio_presskits.visibility.site_fallback", default: "this site")
          return fallback unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

          Rails.application.class.module_parent_name.to_s.titleize.presence || fallback
        end
      end
    end
  end
end
