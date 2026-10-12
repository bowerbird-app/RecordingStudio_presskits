# frozen_string_literal: true

require "recording_studio_presskits/kit_download/filenames"
require "recording_studio_presskits/kit_download/manifest"
require "recording_studio_presskits/kit_download/text_file"

module RecordingStudioPresskits
  class KitDownload # rubocop:disable Metrics/ClassLength
    ACTION = :"presskits.kit_download"
    EXPORT_SCOPE = :public
    TEXT_FILENAME = "kit.txt"
    DEFAULT_AUDIENCE_ICONS = {
      public: "globe-alt",
      signed_in: "user",
      granted: "lock-closed"
    }.freeze
    DEFAULT_CUSTOM_AUDIENCE_ICON = "user-group"

    class << self
      def audience_defaults
        {
          allowed: default_allowed_audiences,
          default: :public,
          granted_roles: %i[download edit admin],
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

      def constrained?(recording)
        audience_options_for(recording).none? { |option| option[:audience] == :public }
      end

      def audience_icon_for(audience)
        key = audience.to_s
        from_config = icon_from_config(key)
        return from_config if from_config.present?

        from_i18n = icon_from_i18n(key)
        return from_i18n if from_i18n.present?

        DEFAULT_AUDIENCE_ICONS.fetch(key.to_sym) do
          icon_from_i18n("default") || DEFAULT_CUSTOM_AUDIENCE_ICON
        end
      end

      def subscribe!
        return unless defined?(RecordingStudioPublishable)
        return if @subscribed

        RecordingStudioPublishable.subscribe(:published) { |event| generate_from(event) }
        RecordingStudioPublishable.subscribe(:unpublished) { |event| invalidate_from(event) }
        RecordingStudioPublishable.subscribe(:revised) { |event| generate_from(event) }
        @subscribed = true
      end

      def manifest_for(recording)
        Manifest.call(recording)
      end

      def generate!(recording)
        return unless downloadable_kit?(recording)
        return unless recording.currently_published?

        recording.downloadable_generate!(
          action: recording.downloadable_action,
          export_scope: recording.downloadable_export_scope
        )
      rescue StandardError => e
        log_lifecycle_error("generate", recording, e)
        nil
      end

      def invalidate!(recording)
        return unless downloadable_kit?(recording)

        recording.downloadable_invalidate!(immediate: true)
      rescue StandardError => e
        log_lifecycle_error("invalidate", recording, e)
        nil
      end

      def allowed?(recording, actor:)
        return false unless downloadable_kit?(recording)
        return false unless defined?(RecordingStudioDownloadable::Authorization)

        RecordingStudioDownloadable::Authorization.allowed?(
          action: recording.downloadable_action,
          actor: actor,
          recording: recording
        )
      rescue StandardError
        false
      end

      private

      def generate_from(event)
        generate!(press_kit_recording(event))
      end

      def invalidate_from(event)
        invalidate!(press_kit_recording(event))
      end

      def press_kit_recording(event)
        payload = event.respond_to?(:payload) ? event.payload : event
        return if payload.blank?

        type = (payload[:recordable_type] || payload["recordable_type"]).to_s
        return unless type == RecordingStudioPresskits.press_kit_type_name

        id = payload[:recording_id] || payload["recording_id"]
        return if id.blank?

        RecordingStudio::Recording.find_by(id: id)
      end

      def icon_from_config(key)
        icons = RecordingStudioPresskits.configuration.download_audience_icons
        return if icons.blank?

        hash = icons.to_h
        value = hash[key] || hash[key.to_sym] || hash[key.to_s]
        value.to_s.strip.presence
      end

      def icon_from_i18n(key)
        return unless defined?(I18n)

        full = "recording_studio_presskits.downloads.audience_icons.#{key}"
        return unless I18n.exists?(full)

        I18n.t(full).to_s.strip.presence
      end

      def default_allowed_audiences
        names = %i[public signed_in granted]
        return names unless defined?(RecordingStudioAccessible)

        names | RecordingStudioAccessible.audience_registry.names
      end

      def downloadable_kit?(recording)
        recording.present? &&
          recording.respond_to?(:downloadable?) &&
          recording.downloadable? &&
          recording.recordable_type == RecordingStudioPresskits.press_kit_type_name
      end

      def log_lifecycle_error(action, recording, error)
        return unless defined?(Rails) && Rails.respond_to?(:logger)

        Rails.logger.warn(
          "[presskits.kit_download] #{action} failed for #{recording&.id}: #{error.class}: #{error.message}"
        )
      end
    end
  end
end
