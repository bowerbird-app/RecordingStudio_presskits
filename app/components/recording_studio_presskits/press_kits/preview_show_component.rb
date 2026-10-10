# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class PreviewShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, reason: nil)
        super()
        @press_kit_recording = press_kit_recording
        @reason = reason
      end

      def title
        recordable&.try(:title).presence || "Press kit"
      end

      def description
        recordable&.try(:description).to_s.strip.presence
      end

      def kit_date
        publishable = @press_kit_recording.try(:current_publishable)
        time = publishable&.try(:publish_at).presence || @press_kit_recording.try(:created_at)
        time&.to_date
      end

      def formatted_date
        return if kit_date.blank?

        I18n.l(kit_date, format: :long)
      end

      def reason
        @reason.presence || Visibility.preview_reason_for(@press_kit_recording)
      end

      def signed_in_reason?
        reason.to_sym == :signed_in
      end

      def explanation
        if signed_in_reason?
          I18n.t("recording_studio_presskits.visibility.preview.sign_in")
        else
          I18n.t("recording_studio_presskits.visibility.preview.need_access")
        end
      end

      def sign_in_path
        Visibility.sign_in_path
      end

      def sign_in_label
        I18n.t("recording_studio_presskits.visibility.preview.sign_in_action")
      end

      private

      def recordable
        @press_kit_recording&.recordable
      end
    end
  end
end
