# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ItemActionRegistration
      private

      def image_update_registration
        action_registration(
          capability: :attachable,
          handler: AttachmentActions::UpdateImage,
          input_contract: image_input,
          summary: "Update an image caption, credit, or alt text"
        )
      end

      def image_remove_registration
        action_registration(
          capability: :trashable,
          handler: AttachmentActions::RemoveImage,
          input_contract: id_input(:image_id),
          summary: "Remove an image from this section",
          required_role: :admin
        )
      end

      def file_update_registration
        action_registration(
          capability: :attachable,
          handler: AttachmentActions::UpdateFile,
          input_contract: file_input,
          summary: "Update a file name or description"
        )
      end

      def file_remove_registration
        action_registration(
          capability: :trashable,
          handler: AttachmentActions::RemoveFile,
          input_contract: id_input(:file_id),
          summary: "Remove a file from this section",
          required_role: :admin
        )
      end

      def image_input
        optional_fields(:image_id, %i[caption credit alt_text])
      end

      def file_input
        optional_fields(:file_id, %i[name description])
      end

      def optional_fields(id_key, names)
        fields = { id_key => { type: :string, required: true, allow_blank: false } }
        names.each { |name| fields[name] = { type: :string, required: false, allow_blank: true } }
        { reject_unknown: true, fields: fields }
      end
    end
  end
end
