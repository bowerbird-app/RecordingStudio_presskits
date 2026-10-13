# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class PressKitPayload
      def self.for(recordable)
        {
          title: recordable.title,
          subtitle: recordable.subtitle,
          description: recordable.description,
          brand_color: recordable.brand_color,
          font_family: recordable.font_family
        }
      end
    end
  end
end
