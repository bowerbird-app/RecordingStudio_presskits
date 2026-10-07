# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def lines
        Credits.visible_lines(@recording)
      end

      def credit_for(line)
        Credits.credit_for(line)&.recordable
      end

      def credit_url(credit)
        FlatPack::AttributeSanitizer.sanitize_url(credit&.url)
      end
    end
  end
end
