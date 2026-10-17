# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ContentRegistration
      def register_text
        register_type("RecordingStudioPresskits::Text", **text_options)
      end

      def register_quote
        register_type("RecordingStudioPresskits::Quote", **quote_options)
      end

      def register_quote_section
        register_type(
          "RecordingStudioPresskits::QuoteSection",
          **empty_section_options,
          capability_actions: %i[reorder_quotes],
          relationships: { quotes: quotes_relationship }
        )
      end

      def register_video_section
        register_type("RecordingStudioPresskits::VideoSection", **video_section_options)
      end

      private

      def text_options
        {
          operations: %i[index show update destroy],
          serializer: method(:text_serializer),
          output_keys: %i[body],
          writable_attributes: %i[body]
        }
      end

      def text_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context)
        { body: Exposure.withhold?(context, source) ? nil : recordable.body }
      end

      def quote_options
        {
          operations: %i[index show create update destroy],
          serializer: QuotePayload.method(:for),
          output_keys: %i[body name role organisation],
          writable_attributes: %i[body name role organisation]
        }
      end

      def quotes_relationship
        child_collection(
          "RecordingStudioPresskits::Quote",
          serializer: QuotePayload.method(:for),
          output_keys: %i[body name role organisation],
          endpoints: %i[index show create update destroy],
          description: "Quotes in this section"
        )
      end

      def video_section_options
        {
          operations: %i[index show],
          serializer: method(:video_section_serializer),
          output_keys: %i[videos],
          capability_actions: %i[add_video update_video remove_video reorder_videos]
        }
      end

      def video_section_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        { videos: VideoPayload.for_recording(source, context: context) }
      end

      def podcast_section_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        { podcasts: PodcastPayload.for_recording(source, context: context) }
      end
    end
  end
end
