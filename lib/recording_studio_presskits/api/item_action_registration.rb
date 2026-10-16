# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ItemActionRegistration
      def register_item_actions
        register_reorder_actions
        register_video_actions
        register_location_actions
        register_attachment_actions
      end

      private

      def register_reorder_actions
        reorder_summaries.each do |name, summary|
          register_section_action(name, reorder_action(summary))
        end
      end

      def reorder_summaries
        {
          reorder_quotes: "Reorder quotes in this section",
          reorder_stats: "Reorder stats in this section",
          reorder_items: "Reorder rows in this list",
          reorder_images: "Reorder images in this section",
          reorder_files: "Reorder files in this section",
          reorder_videos: "Reorder videos in this section",
          reorder_podcasts: "Reorder episodes in this section",
          reorder_locations: "Reorder places in this section"
        }
      end

      def reorder_action(summary)
        action_registration(
          capability: :orderable,
          handler: ReorderChildren,
          input_contract: reorder_sections_input,
          summary: summary
        )
      end

      def register_video_actions
        register_section_action(:add_video, video_add_registration)
        register_section_action(:update_video, video_update_registration)
        register_section_action(:remove_video, video_remove_registration)
      end

      def register_location_actions
        register_section_action(:set_location, location_set_registration)
        register_section_action(:update_location, location_update_registration)
        register_section_action(:clear_location, location_clear_registration)
      end

      def register_attachment_actions
        register_section_action(:update_image, image_update_registration)
        register_section_action(:remove_image, image_remove_registration)
        register_section_action(:update_file, file_update_registration)
        register_section_action(:remove_file, file_remove_registration)
      end

      def id_input(name)
        {
          reject_unknown: true,
          fields: {
            name => { type: :string, required: true, allow_blank: false }
          }
        }
      end
    end
  end
end
