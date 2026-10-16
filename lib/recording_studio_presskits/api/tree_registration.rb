# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    # Press kit and kit section registration. Rows are [name, type, serializer, keys, endpoints, description].
    module TreeRegistration
      KIT_SECTION_ROWS = [
        [:texts, "RecordingStudioPresskits::Text", :text_serializer, %i[body],
         %i[index show update destroy], "Text in this section"],
        [:quote_sections, "RecordingStudioPresskits::QuoteSection", :container_serializer, %i[kind],
         %i[index show], "Quotes block in this section"],
        [:stats_sections, "RecordingStudioPresskits::StatsSection", :container_serializer, %i[kind],
         %i[index show], "Stats block in this section"],
        [:credits_sections, "RecordingStudioPresskits::CreditsSection", :container_serializer, %i[kind],
         %i[index show], "Credits block in this section"],
        [:list_sections, "RecordingStudioPresskits::ListSection", :container_serializer, %i[kind],
         %i[index show], "List block in this section"],
        [:podcast_sections, "RecordingStudioPresskits::PodcastSection", :podcast_section_serializer, %i[podcasts],
         %i[index show], "Podcast block in this section"],
        [:video_sections, "RecordingStudioPresskits::VideoSection", :video_section_serializer, %i[videos],
         %i[index show], "Video block in this section"],
        [:location_sections, "RecordingStudioPresskits::LocationSection", :location_section_serializer, %i[locations],
         %i[index show], "Location block in this section"],
        [:image_sections, "RecordingStudioPresskits::Images", :image_section_serializer, %i[images],
         %i[index show], "Images block in this section"],
        [:file_sections, "RecordingStudioPresskits::Files", :files_serializer, %i[files],
         %i[index show], "Files block in this section"],
        [:menu_sections, "RecordingStudioPresskits::MenuSection", :menu_section_serializer, MenuPayload::KEYS,
         %i[index show update], "Menu in this section"]
      ].freeze

      def register_press_kit
        register_type(
          "RecordingStudioPresskits::PressKit",
          **press_kit_options,
          relationships: { kit_sections: kit_sections_relationship }
        )
      end

      def register_kit_section
        register_type("RecordingStudioPresskits::KitSection", **kit_section_options)
      end

      private

      def press_kit_options
        {
          operations: %i[index show create update destroy],
          serializer: PressKitPayload.method(:for),
          output_keys: PressKitPayload::KEYS,
          writable_attributes: PressKitPayload::WRITABLE,
          sortable_attributes: %i[title],
          capability_actions: %i[publish unpublish update_publishable create_section reorder_sections]
        }
      end

      def kit_section_options
        {
          operations: %i[index show update destroy],
          serializer: method(:kit_section_serializer),
          output_keys: kit_section_keys,
          writable_attributes: %i[title subtitle],
          capability_actions: %i[remove_section],
          relationships: kit_section_relationships
        }
      end

      def kit_sections_relationship
        child_collection(
          "RecordingStudioPresskits::KitSection",
          serializer: method(:kit_section_serializer),
          output_keys: kit_section_keys,
          endpoints: %i[index show update destroy],
          description: "Sections in this press kit"
        )
      end

      def kit_section_serializer(recordable, recording: nil, context: nil, **)
        source = Exposure.named_recording(recording: recording, context: context)
        SectionPayload.for(recordable, source, context: context)
      end

      def kit_section_keys
        %i[title subtitle content_type content_id videos stats locations podcasts files items images]
      end

      def kit_section_relationships
        KIT_SECTION_ROWS.to_h { |row| [row[0], relationship_from(row)] }
      end

      def relationship_from(row)
        content_relationship(row[1], method(row[2]), row[3], row[4], row[5])
      end

      def container_serializer(...)
        ContainerPayload.for(...)
      end

      def image_section_serializer(...)
        ImagePayload.for_section(...)
      end

      def menu_section_serializer(...)
        MenuPayload.for(...)
      end
    end
  end
end
