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
          relationships: { podcasts: podcasts_relationship }
        )
      end

      def podcasts_relationship
        child_collection(
          "RecordingStudioPresskits::Podcast",
          serializer: PodcastPayload.method(:for),
          output_keys: PodcastPayload::KEYS,
          endpoints: %i[index show create update destroy],
          description: "Episodes in this section"
        )
      end

      def register_podcast
        register_type(
          "RecordingStudioPresskits::Podcast",
          operations: %i[index show create update destroy],
          serializer: PodcastPayload.method(:for),
          output_keys: PodcastPayload::KEYS,
          writable_attributes: %i[url title show_name aired_on duration]
        )
      end
    end
  end
end
