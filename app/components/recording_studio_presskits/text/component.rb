# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @text = recording.recordable
      end
    end
  end
end
