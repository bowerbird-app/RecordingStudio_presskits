# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class PressKitPayload
      KEYS = %i[title subtitle description brand_color font_family text_color corner_style].freeze
      WRITABLE = %i[title subtitle description brand_color font_family text_color corner_style].freeze

      def self.for(recordable, context: nil)
        payload = KEYS.index_with { |name| recordable.public_send(name) }
        return payload unless Exposure.withhold?(context, recording_for(recordable, context))

        payload.merge(description: nil)
      end

      def self.recording_for(recordable, context)
        return context.recording if context.respond_to?(:recording) && context.recording.present?
        return unless defined?(RecordingStudio::Recording)

        RecordingStudio::Recording.find_by(recordable: recordable)
      end
      private_class_method :recording_for
    end
  end
end
