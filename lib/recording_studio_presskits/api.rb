# frozen_string_literal: true

require "recording_studio_presskits/api/exposure"
require "recording_studio_presskits/api/gate"
require "recording_studio_presskits/api/gate_listing"
require "recording_studio_presskits/api/quote_payload"
require "recording_studio_presskits/api/stat_payload"
require "recording_studio_presskits/api/credit_payload"
require "recording_studio_presskits/api/credit_line_payload"
require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/podcast_payload"
require "recording_studio_presskits/api/location_payload"
require "recording_studio_presskits/api/list_payload"
require "recording_studio_presskits/api/file_payload"
require "recording_studio_presskits/api/image_payload"
require "recording_studio_presskits/api/menu_payload"
require "recording_studio_presskits/api/container_payload"
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
require "recording_studio_presskits/api/image_registration"
require "recording_studio_presskits/api/menu_registration"
require "recording_studio_presskits/api/resource_io"
require "recording_studio_presskits/api/reorder_children"
require "recording_studio_presskits/api/video_actions"
require "recording_studio_presskits/api/location_actions"
require "recording_studio_presskits/api/attachment_actions"
require "recording_studio_presskits/api/item_action_registration"
require "recording_studio_presskits/api/video_action_registration"
require "recording_studio_presskits/api/place_action_registration"
require "recording_studio_presskits/api/attachment_action_registration"
require "recording_studio_presskits/api/handler_registration"
require "recording_studio_presskits/api/tree_registration"
require "recording_studio_presskits/api/content_registration"

module RecordingStudioPresskits
  module Api
    extend SectionActionRegistration
    extend CreditRegistration
    extend StatRegistration
    extend LocationRegistration
    extend ListRegistration
    extend PodcastRegistration
    extend ImageRegistration
    extend MenuRegistration
    extend ItemActionRegistration
    extend HandlerRegistration
    extend TreeRegistration
    extend ContentRegistration

    class << self
      def register!
        return unless defined?(::RecordingStudioApi)

        register_recordable_types
        register_lists!
        register_section_actions
        register_item_actions
        register_resource_handlers!
      end

      private

      def register_recordable_types
        register_kit_types
        register_content_types
      end

      def register_kit_types
        register_press_kit
        register_kit_section
        register_text
        register_quote
        register_quote_section
      end

      def register_content_types
        register_stats!
        register_credits!
        register_video_section
        register_podcasts!
        register_location_section
        register_images!
        register_menu!
      end

      def content_relationship(child_type, serializer, output_keys, endpoints, description)
        child_collection(
          child_type,
          serializer: serializer,
          output_keys: output_keys,
          endpoints: endpoints,
          description: description
        )
      end

      def child_collection(child_type, serializer:, output_keys:, endpoints:, description:)
        {
          source: :children,
          child_type: child_type,
          many: true,
          limit: 500,
          endpoints: endpoints,
          serializer: serializer,
          output_keys: output_keys,
          description: description
        }
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
