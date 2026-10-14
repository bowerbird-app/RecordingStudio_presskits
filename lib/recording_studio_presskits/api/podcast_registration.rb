# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module PodcastRegistration
      def register_podcasts!
        register_podcast_section
        register_podcast
      end

      private

      def register_podcast_section
        register_type(
          "RecordingStudioPresskits::PodcastSection",
          operations: %i[index show],
          serializer: podcast_section_serializer,
          output_keys: %i[podcasts]
        )
      end

      def register_podcast
        register_type(
          "RecordingStudioPresskits::Podcast",
          operations: %i[show update],
          serializer: ->(recordable, context: nil, **) { PodcastPayload.for(recordable, context: context) },
          output_keys: PodcastPayload::KEYS,
          writable_attributes: %i[url title show_name aired_on duration]
        )
      end

      def podcast_section_serializer
        lambda { |_recordable, recording: nil, context: nil, **|
          source = Exposure.named_recording(recording: recording, context: context)
          { podcasts: PodcastPayload.for_recording(source, context: context) }
        }
      end
    end
  end
end
