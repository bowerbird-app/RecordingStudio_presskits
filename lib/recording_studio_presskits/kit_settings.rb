# frozen_string_literal: true

module RecordingStudioPresskits
  # Sidecar settings for a kit recording. Not a recordable: changing the
  # fallback must not snapshot the kit or fire Publishable download rebuilds.
  class KitSettings
    DEFAULT_FALLBACK = :preview

    class << self
      def fallback_for(recording)
        return DEFAULT_FALLBACK if recording.blank?

        stored = KitSetting.find_by(recording_id: recording.id)&.visibility_fallback
        normalize(stored)
      end

      def save_fallback!(recording:, fallback:, actor: nil)
        raise ArgumentError, "recording is required" if recording.blank?

        value = normalize(fallback)
        setting = KitSetting.find_or_initialize_by(recording_id: recording.id)
        previous = normalize(setting.visibility_fallback.presence)
        setting.visibility_fallback = value.to_s
        setting.save!
        log_change!(recording, actor, previous, value) if previous != value
        value
      end

      private

      def normalize(value)
        name = value.to_s.to_sym
        Visibility::FALLBACKS.include?(name) ? name : DEFAULT_FALLBACK
      end

      def log_change!(recording, actor, previous, value)
        return unless recording.respond_to?(:log_event!)

        recording.log_event!(
          action: "visibility_fallback_changed",
          actor: actor,
          metadata: { previous_fallback: previous.to_s, visibility_fallback: value.to_s }
        )
      end
    end
  end
end
