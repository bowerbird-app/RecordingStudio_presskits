# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class PressKitPayload
      def self.for(recordable)
        {
          title: recordable.title,
          description: recordable.description,
          cover_style: recordable.resolved_cover_style,
          cover_color: recordable.resolved_cover_color
        }
      end
    end
  end
end
