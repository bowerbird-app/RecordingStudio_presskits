# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        lines.any?
      end

      def lines
        Credits.visible_lines(@recording)
      end

      def credit_url(line)
        FlatPack::AttributeSanitizer.sanitize_url(line.recordable.url)
      end
    end
  end
end
