# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class PodcastPayload
      KEYS = %i[title show_name url aired_on duration service embed_url].freeze

      def self.for(recordable, context: nil)
        return KEYS.index_with { nil } if Exposure.withhold?(context, recording_for(recordable, context))

        fields(recordable)
      end

      def self.fields(recordable)
        embed = PodcastEmbed.for(recordable.url)
        {
          title: recordable.title,
          show_name: recordable.show_name,
          url: recordable.url,
          aired_on: recordable.aired_on&.iso8601,
          duration: recordable.duration,
          service: embed.service,
          embed_url: embed.embed_url
        }
      end
      private_class_method :fields

      def self.for_recording(recording, context: nil)
        return [] if Exposure.withhold?(context, recording)

        PodcastSection.active_podcasts(recording).map { |child| PodcastPayload.for(child.recordable) }
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
