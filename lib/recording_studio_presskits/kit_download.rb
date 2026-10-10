# frozen_string_literal: true

require "recording_studio_presskits/kit_download/filenames"
require "recording_studio_presskits/kit_download/manifest"
require "recording_studio_presskits/kit_download/text_file"

module RecordingStudioPresskits
  class KitDownload
    ACTION = :"presskits.kit_download"
    EXPORT_SCOPE = :public
    TEXT_FILENAME = "kit.txt"

    class << self
      def audience_defaults
        {
          allowed: %i[public signed_in granted],
          default: :granted,
          granted_roles: %i[download edit admin],
          granted_override: true,
          manage_role: :admin
        }
      end

      def configure_audience!
        return unless defined?(RecordingStudioAccessible)

        RecordingStudioAccessible.configuration.action_audiences[ACTION] ||= audience_defaults.dup
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
