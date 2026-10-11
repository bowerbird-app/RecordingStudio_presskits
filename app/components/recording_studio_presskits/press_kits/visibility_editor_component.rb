# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class VisibilityEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, audience:, options:, fallback:, constrained: false)
        super()
        @press_kit_recording = press_kit_recording
        @audience = audience
        @options = Array(options)
        @fallback = fallback
        @constrained = constrained
      end

      def audience_value
        @audience.to_s
      end

      def fallback_value
        @fallback.to_s
      end

      def public_audience?
        audience_value == "public"
      end

      def constrained?
        @constrained
      end

      def select_options
        @options.map { |option| { label: option[:label], value: option[:audience].to_s } }
      end

      def fallback_options
        %i[preview hidden].map { |name| fallback_option(name) }
      end

      private

      def fallback_option(name)
        {
          label: I18n.t("recording_studio_presskits.visibility.fallback.#{name}"),
          value: name.to_s,
          icon: fallback_icon(name)
        }
      end

      def fallback_icon(name)
        name.to_sym == :hidden ? "eye-slash" : "eye"
      end
    end
  end
end
