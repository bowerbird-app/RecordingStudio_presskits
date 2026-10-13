# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class InlineComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @text = recording.recordable
        @update_path = update_path
      end

      def body_html
        FlatPack::RichTextSanitizer.sanitize(@text.body.to_s)
      end

      def body_label
        I18n.t("recording_studio_presskits.editor.text_body")
      end

      def body_placeholder
        I18n.t("recording_studio_presskits.editor.placeholder.text")
      end
    end
  end
end
