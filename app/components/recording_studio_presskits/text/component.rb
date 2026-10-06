# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @text = recording.recordable
      end

      def section_title
        @text.title.to_s.strip.presence
      end

      def body_html
        FlatPack::RichTextSanitizer.sanitize(@text.body.to_s)
      end
    end
  end
end
