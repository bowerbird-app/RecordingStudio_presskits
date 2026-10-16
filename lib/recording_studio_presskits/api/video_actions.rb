# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module VideoActions
      FIELDS = %i[title url description duration thumbnail_url].freeze

      class Add
        def self.call(context)
          prepare!(context)
          SectionAction.reject!("url is required") if context.params[:url].blank?
          record_video(context)
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.prepare!(context)
          SectionAction.authorize!(context)
          SectionAction.require_recording!(context.recording, VideoSection, "expected a video section")
        end

        def self.record_video(context)
          context.recording.record(RecordingStudioVideo::Video, **record_options(context)) do |video|
            video.assign_attributes(context.params.slice(*FIELDS))
          end
        end

        def self.record_options(context)
          { parent_recording: context.recording, actor: context.access_grant.actor }
        end
        private_class_method :record_video, :record_options
      end

      class Update
        def self.call(context)
          Add.prepare!(context)
          revise_video(context)
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.revise_video(context)
          video = find_video(context)
          context.recording.root_recording.revise(video, actor: context.access_grant.actor) do |recordable|
            recordable.assign_attributes(context.params.slice(*FIELDS))
          end
        end
        private_class_method :revise_video

        def self.find_video(context)
          video = VideoSection.active_videos(context.recording).find_by(id: context.params[:video_id])
          SectionAction.reject!("That video is not in this section") if video.blank?

          video
        end
        private_class_method :find_video
      end

      class Remove
        def self.call(context)
          SectionAction.authorize_admin!(context)
          SectionAction.require_recording!(context.recording, VideoSection, "expected a video section")
          video = VideoSection.active_videos(context.recording).find_by(id: context.params[:video_id])
          SectionAction.reject!("That video is not in this section") if video.blank?

          video.recording_studio_trashable_trash!(actor: context.access_grant.actor)
          video
        end
      end
    end
  end
end
