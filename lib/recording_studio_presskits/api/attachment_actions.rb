# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module AttachmentActions
      class UpdateImage
        def self.call(context)
          AttachmentActions.revise(
            context, Images, :image_id, %i[caption credit alt_text], "That image is not in this section"
          )
        end
      end

      class UpdateFile
        def self.call(context)
          AttachmentActions.revise(context, Files, :file_id, %i[name description], "That file is not in this section")
        end
      end

      class RemoveImage
        def self.call(context)
          AttachmentActions.trash(context, Images, :image_id, "That image is not in this section")
        end
      end

      class RemoveFile
        def self.call(context)
          AttachmentActions.trash(context, Files, :file_id, "That file is not in this section")
        end
      end

      def self.revise(context, kind, id_key, fields, missing)
        SectionAction.authorize!(context)
        require_kind!(context, kind)
        child = find_child(context, id_key, missing)
        child.revise_attachment_metadata(actor: context.access_grant.actor, **context.params.slice(*fields))
        child
      end

      def self.trash(context, kind, id_key, missing)
        SectionAction.authorize_admin!(context)
        require_kind!(context, kind)
        child = find_child(context, id_key, missing)
        child.recording_studio_trashable_trash!(actor: context.access_grant.actor)
        child
      end

      def self.require_kind!(context, kind)
        label = kind.name.demodulize.underscore.humanize.downcase
        SectionAction.require_recording!(context.recording, kind, "expected a #{label} section")
      end

      def self.find_child(context, id_key, missing)
        child = context.recording.child_recordings.find_by(id: context.params[id_key])
        return child if attachment?(child)

        SectionAction.reject!(missing)
      end

      def self.attachment?(child)
        child.present? && child.recordable_type == "RecordingStudioAttachable::Attachment"
      end
    end
  end
end
