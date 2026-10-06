# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionImagesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless section_recording && attachment_recording

      redirect_after_remove(remove_attachment)
    end

    private

    def remove_attachment
      RecordingStudioAttachable::Services::RemoveAttachment.call(
        attachment_recording: attachment_recording,
        actor: presskits_actor
      )
    end

    def redirect_after_remove(result)
      if result.success?
        redirect_to section_edit_path, notice: "Image removed."
      else
        redirect_to section_edit_path, alert: result.error.presence || "Could not remove that image."
      end
    end

    def section_recording
      return @section_recording if defined?(@section_recording)

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
    end

    def attachment_recording
      return @attachment_recording if defined?(@attachment_recording)

      @attachment_recording = find_attachment_recording
    end

    def find_attachment_recording
      images = images_recording
      return unless images

      images.recordings_query(
        include_children: true,
        type: "RecordingStudioAttachable::Attachment",
        parent_id: images.id
      ).where(trashed_at: nil).find_by(id: params[:id])
    end

    def images_recording
      content = KitQuery.section_content(section_recording)
      content if content&.recordable.is_a?(Images)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
