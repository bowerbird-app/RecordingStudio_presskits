# frozen_string_literal: true

require "recording_studio_presskits/api/quote_payload"
require "recording_studio_presskits/api/fact_payload"
require "recording_studio_presskits/api/credit_payload"
require "recording_studio_presskits/api/credit_line_payload"
require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/location_payload"
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
require "recording_studio_presskits/api/fact_registration"

module RecordingStudioPresskits
  module Api
    extend SectionActionRegistration
    extend CreditRegistration
    extend FactRegistration

    class << self
      def register!
        return unless defined?(::RecordingStudioApi)

        register_press_kit
        register_kit_section
        register_text
        register_quote
        register_quote_section
        register_facts!
        register_credits!
        register_video_section
        register_location_section
        register_section_actions
      end

      private

      def register_press_kit
        register_type(
          "RecordingStudioPresskits::PressKit",
          operations: %i[show update],
          serializer: ->(recordable, **) { PressKitPayload.for(recordable) },
          output_keys: %i[title description cover_style cover_color cover_text_color],
          writable_attributes: %i[cover_style cover_color cover_text_color],
          capability_actions: %i[create_section reorder_sections]
        )
      end

      def register_kit_section
        register_type(
          "RecordingStudioPresskits::KitSection",
          operations: %i[index show update],
          serializer: ->(recordable, recording: nil, **) { SectionPayload.for(recordable, recording) },
          output_keys: %i[title subtitle content_type content_id videos display facts locations],
          writable_attributes: %i[title subtitle],
          capability_actions: %i[remove_section]
        )
      end

      def register_text
        register_type(
          "RecordingStudioPresskits::Text",
          operations: %i[show update],
          serializer: ->(recordable, **) { { body: recordable.body } },
          output_keys: %i[body],
          writable_attributes: %i[body]
        )
      end

      def register_quote
        ::RecordingStudioApi.register_recordable_type_api(
          "RecordingStudioPresskits::Quote",
          **quote_registration
        )
      end

      def quote_registration
        {
          operations: %i[index show create update destroy],
          serializer: quote_serializer,
          output_keys: quote_keys,
          writable_attributes: quote_keys
        }
      end

      def quote_keys
        %i[body name role organisation]
      end

      def quote_serializer
        ->(recordable, **) { QuotePayload.for(recordable) }
      end

      def register_quote_section
        register_type("RecordingStudioPresskits::QuoteSection", **empty_section_options)
      end

      def register_video_section
        register_type(
          "RecordingStudioPresskits::VideoSection",
          operations: %i[index show],
          serializer: lambda { |_recordable, recording: nil, **|
            { videos: VideoPayload.for_recording(recording) }
          },
          output_keys: %i[videos]
        )
      end

      def register_location_section
        register_type(
          "RecordingStudioPresskits::LocationSection",
          operations: %i[index show],
          serializer: lambda { |_recordable, recording: nil, **|
            { locations: LocationPayload.for_recording(recording) }
          },
          output_keys: %i[locations]
        )
      end

      def register_type(type_name, **)
        ::RecordingStudioApi.register_recordable_type_api(type_name, **)
      end

      def empty_section_options
        {
          operations: %i[index show],
          serializer: empty_serializer,
          output_keys: []
        }
      end

      def empty_serializer
        ->(_recordable) { {} }
      end
    end
  end
end
