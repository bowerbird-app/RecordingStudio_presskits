# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastImagesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless podcast_recording && attachment_recording

      redirect_after_remove(remove_attachment)
    end

    private

    attr_reader :section_recording, :podcast_section_recording

    def remove_attachment
      RecordingStudioAttachable::Services::RemoveAttachment.call(
        attachment_recording: attachment_recording,
        actor: presskits_actor
      )
    end

    def redirect_after_remove(result)
      if result.success?
        redirect_to podcast_edit_path, notice: "Cover removed."
      else
        redirect_to podcast_edit_path, alert: result.error.presence || "Could not remove that cover."
      end
    end

    def podcast_recording
      return @podcast_recording if defined?(@podcast_recording)

      @podcast_recording = find_podcast
    end

    def attachment_recording
      return @attachment_recording if defined?(@attachment_recording)

      @attachment_recording = find_attachment
    end

    def find_podcast
      PodcastSection.active_podcasts(podcast_section_recording).find_by(id: params[:podcast_id])
    end

    def find_attachment
      return unless podcast_recording

      podcast_recording.child_recordings.where(attachment_scope).first
    end

    def attachment_scope
      { trashed_at: nil, recordable_type: "RecordingStudioAttachable::Attachment" }
    end

    def podcast_edit_path
      edit_press_kit_section_podcast_path(@press_kit_recording, section_recording, podcast_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @podcast_section_recording = KitQuery.section_content(@section_recording)
      return if @podcast_section_recording&.recordable.is_a?(PodcastSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
