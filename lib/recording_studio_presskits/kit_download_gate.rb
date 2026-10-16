# frozen_string_literal: true

module RecordingStudioPresskits
  # One confirmation per press kit, shared by the kit zip and every images
  # section zip. Downloadable calls these methods; this class does not decide
  # who is allowed to download.
  class KitDownloadGate
    SESSION_KEY = :presskits_download_gate

    class << self
      def register!
        return unless defined?(RecordingStudioDownloadable)

        RecordingStudioDownloadable.configure do |config|
          config.register_download_gate(KitDownload::ACTION, self)
          config.register_download_gate(ImagesDownload::ACTION, self)
        end
      end

      def satisfied?(recording:, actor:, request:) # rubocop:disable Lint/UnusedMethodArgument
        kit = kit_for(recording)
        return false if kit.nil?

        confirmed?(entry_for(kit, entries(request&.session&.[](SESSION_KEY))))
      end

      def continuation_url(recording:, actor:, request:) # rubocop:disable Lint/UnusedMethodArgument
        gate_path(recording_id: recording.id)
      end

      def component
        DownloadGateComponent
      end

      def metadata_for(recording:, actor:) # rubocop:disable Lint/UnusedMethodArgument
        kit = kit_for(recording)
        return {} if kit.nil?
        return {} unless defined?(Current) && Current.respond_to?(:download_gate)

        return {} unless confirmed?(entry_for(kit, entries(Current.download_gate)))

        { "confirmed" => true }
      end

      def form_path
        gate_path
      end

      def kit_for(recording)
        current = recording
        seen = {}.compare_by_identity
        while current && !seen[current]
          seen[current] = true
          return current if press_kit?(current)

          current = current.respond_to?(:parent_recording) ? current.parent_recording : nil
        end
        nil
      end

      def covers?(recording)
        press_kit?(recording) || images?(recording)
      end

      def entries(store)
        return {} unless store.is_a?(Hash)

        store.each_with_object({}) do |(key, value), memo|
          next unless value.is_a?(Hash)

          memo[key.to_s] = value.stringify_keys
        end
      end

      def entry_for(recording, store)
        return {} if recording.nil?

        entries(store)[recording.id.to_s] || {}
      end

      def confirmed?(entry)
        entry.is_a?(Hash) && entry["confirmed"] == true
      end

      def modal_id(recording)
        "download-gate-modal-#{recording.id}"
      end

      def frame_id(recording)
        "download-gate-step-#{recording.id}"
      end

      private

      def gate_path(**params)
        Engine.routes.url_helpers.download_gate_path(**params)
      end

      def press_kit?(recording)
        recording&.recordable.is_a?(RecordingStudioPresskits::PressKit)
      end

      def images?(recording)
        recording&.recordable.is_a?(RecordingStudioPresskits::Images)
      end
    end
  end

  # Copies the gate session onto Current so Downloadable can read
  # `metadata_for` on a later package request. PackagesController skips the
  # host actor filter, so this callback has to live on ActionController::Base.
  module DownloadGateSession
    private

    def remember_presskits_download_gate
      return unless defined?(Current) && Current.respond_to?(:download_gate=)

      Current.download_gate = session[KitDownloadGate::SESSION_KEY]
    rescue StandardError
      nil
    end
  end
end
