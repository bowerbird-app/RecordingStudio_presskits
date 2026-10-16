# frozen_string_literal: true

require "recording_studio_presskits/api/exposure"
require "recording_studio_presskits/api/quote_payload"
require "recording_studio_presskits/api/stat_payload"
require "recording_studio_presskits/api/credit_payload"
require "recording_studio_presskits/api/credit_line_payload"
require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/podcast_payload"
require "recording_studio_presskits/api/location_payload"
require "recording_studio_presskits/api/list_payload"
require "recording_studio_presskits/api/file_payload"
require "recording_studio_presskits/api/section_payload"
require "recording_studio_presskits/api/section_action"
require "recording_studio_presskits/api/create_section"
require "recording_studio_presskits/api/reorder_sections"
require "recording_studio_presskits/api/remove_section"
require "recording_studio_presskits/api/add_credit"
require "recording_studio_presskits/api/reorder_credits"
require "recording_studio_presskits/api/remove_credit"
require "recording_studio_presskits/api/section_action_registration"
require "recording_studio_presskits/api/credit_registration"
require "recording_studio_presskits/api/stat_registration"
require "recording_studio_presskits/api/file_registration"
require "recording_studio_presskits/api/location_registration"
require "recording_studio_presskits/api/list_registration"
require "recording_studio_presskits/api/podcast_registration"

module RecordingStudioPresskits
  module Api
    extend SectionActionRegistration
    extend CreditRegistration
    extend StatRegistration
    extend LocationRegistration
    extend ListRegistration
    extend PodcastRegistration

    class << self
      def register!
        return unless defined?(::RecordingStudioApi)

        register_recordable_types
        register_lists!
        register_section_actions
      end

      def register_recordable_types
        register_press_kit
        register_kit_section
        register_text
        register_quote
        register_quote_section
        register_stats!
        register_credits!
        register_video_section
        register_podcasts!
        register_location_section
      end

      private

      def register_press_kit
        register_type(
          "RecordingStudioPresskits::PressKit",
          operations: %i[show update],
          serializer: ->(recordable, context: nil, **) { PressKitPayload.for(recordable, context: context) },
          output_keys: PressKitPayload::KEYS,
          writable_attributes: %i[brand_color font_family text_color corner_style],
          capability_actions: %i[create_section reorder_sections]
        )
      end

      def register_kit_section
        register_type(
          "RecordingStudioPresskits::KitSection",
          operations: %i[index show update],
          serializer: method(:kit_section_serializer),
          output_keys: %i[title subtitle content_type content_id videos stats locations podcasts files items],
          writable_attributes: %i[title subtitle],
          capability_actions: %i[remove_section]
        )
      end

      def kit_section_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context)
        SectionPayload.for(recordable, source, context: context)
      end

      def register_text
        register_type(
          "RecordingStudioPresskits::Text",
          operations: %i[show update],
          serializer: method(:text_serializer),
          output_keys: %i[body],
          writable_attributes: %i[body]
        )
      end

      def text_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context)
        body = Exposure.withhold?(context, source) ? nil : recordable.body
        { body: body }
      end

      def register_quote
        register_type(
          "RecordingStudioPresskits::Quote",
          operations: %i[index show create update destroy],
          serializer: ->(recordable, context: nil, **) { QuotePayload.for(recordable, context: context) },
          output_keys: %i[body name role organisation],
          writable_attributes: %i[body name role organisation]
        )
      end

      def register_quote_section
        register_type("RecordingStudioPresskits::QuoteSection", **empty_section_options)
      end

      def register_video_section
        register_type(
          "RecordingStudioPresskits::VideoSection",
          operations: %i[index show],
          serializer: method(:video_section_serializer),
          output_keys: %i[videos]
        )
      end

      def video_section_serializer(_recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context)
        { videos: VideoPayload.for_recording(source, context: context) }
      end

      def register_type(type_name, **)
        ::RecordingStudioApi.register_recordable_type_api(type_name, **)
      end

      def empty_section_options
        { operations: %i[index show] }
      end
    end
  end
end
