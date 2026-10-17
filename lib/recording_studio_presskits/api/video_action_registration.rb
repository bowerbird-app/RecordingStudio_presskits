# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ItemActionRegistration
      private

      def video_add_registration
        action_registration(
          capability: :videos,
          handler: VideoActions::Add,
          input_contract: video_fields(url_required: true),
          summary: "Add a video to this section"
        )
      end

      def video_update_registration
        action_registration(
          capability: :videos,
          handler: VideoActions::Update,
          input_contract: video_fields(url_required: false, video_id: true),
          summary: "Update a video in this section"
        )
      end

      def video_remove_registration
        action_registration(
          capability: :trashable,
          handler: VideoActions::Remove,
          input_contract: id_input(:video_id),
          summary: "Remove a video from this section",
          required_role: :admin
        )
      end

      def video_fields(url_required:, video_id: false)
        fields = video_field_definitions(url_required)
        fields[:video_id] = { type: :string, required: true, allow_blank: false } if video_id
        { reject_unknown: true, fields: fields }
      end

      def video_field_definitions(url_required)
        {
          title: { type: :string, required: false, allow_blank: true },
          url: { type: :string, required: url_required, allow_blank: !url_required },
          description: { type: :string, required: false, allow_blank: true },
          duration: { type: :string, required: false, allow_blank: true },
          thumbnail_url: { type: :string, required: false, allow_blank: true }
        }
      end
    end
  end
end
