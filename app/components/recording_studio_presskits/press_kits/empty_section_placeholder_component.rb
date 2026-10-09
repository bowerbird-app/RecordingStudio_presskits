# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class EmptySectionPlaceholderComponent < ViewComponent::Base
      PLACEHOLDER_KEYS = {
        "RecordingStudioPresskits::Text" => "text",
        "RecordingStudioPresskits::Images" => "images",
        "RecordingStudioPresskits::QuoteSection" => "quotes",
        "RecordingStudioPresskits::FactsSection" => "facts",
        "RecordingStudioPresskits::CreditsSection" => "credits",
        "RecordingStudioPresskits::VideoSection" => "video"
      }.freeze

      def initialize(content_type:, edit_path:)
        super()
        @content_type = content_type.to_s
        @edit_path = edit_path
      end

      def title
        key = PLACEHOLDER_KEYS.fetch(@content_type, "generic")
        I18n.t("recording_studio_presskits.editor.placeholder.#{key}")
      end

      def add_label
        I18n.t("recording_studio_presskits.editor.add_content")
      end
    end
  end
end
