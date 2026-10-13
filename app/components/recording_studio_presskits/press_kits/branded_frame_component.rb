# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    # One element around a public kit or a host embed. The style string
    # redeclares Flatpack's primary, button, and ring tokens, which are
    # resolved on the theme root, so they have to sit on this wrapper.
    # Never on <html>. A nil style leaves the theme as it is.
    class BrandedFrameComponent < ViewComponent::Base
      def initialize(press_kit_recording:, id:, branding: true)
        super()
        @press_kit_recording = press_kit_recording
        @id = id
        @branding = branding
      end

      def call
        return content unless @branding

        content_tag(:div, content, **wrapper_options)
      end

      private

      def wrapper_options
        options = { id: @id }
        style = RecordingStudioPresskits.branding_style_for(@press_kit_recording)
        options[:style] = style if style.present?
        options
      end
    end
  end
end
