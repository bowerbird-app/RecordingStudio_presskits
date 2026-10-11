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

      def reason
        @reason.presence || Visibility.preview_reason_for(@press_kit_recording)
      end

      def signed_in_reason?
        reason.to_sym == :signed_in
      end

      def explanation
        if signed_in_reason?
          I18n.t(
            "recording_studio_presskits.visibility.preview.sign_in",
            site_name: Visibility.site_name
          )
        else
          I18n.t("recording_studio_presskits.visibility.preview.need_access")
        end
      end

      def heading
        I18n.t("recording_studio_presskits.visibility.preview.heading")
      end

      def heading_component
        SectionHeadingComponent.new(
          title: heading,
          size: :lg,
          spacing: :md,
          level: :h2,
          anchor_link: false
        )
      end

      def show_auth_actions?
        signed_in_reason?
      end

      def sign_in_path
        Visibility.sign_in_path
      end

      def registration_path
        Visibility.registration_path
      end

      def sign_in_label
        I18n.t("recording_studio_presskits.visibility.preview.sign_in_action")
      end

      def register_label
        I18n.t("recording_studio_presskits.visibility.preview.register_action")
      end

      private

      def recordable
        @press_kit_recording&.recordable
      end
    end
  end
end
