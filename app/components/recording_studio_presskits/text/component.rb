# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @text = recording.recordable
      end

      def render?
        Loofah.fragment(body_html.to_s).text.squish.present?
      end

      def body_html
        FlatPack::RichTextSanitizer.sanitize(@text.body.to_s)
      end
    end
  end
end
