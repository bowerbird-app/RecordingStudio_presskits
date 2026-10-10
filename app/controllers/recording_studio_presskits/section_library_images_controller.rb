# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionLibraryImagesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :require_images_section!

    def index
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @picker_libraries = picker_libraries
      @library = selected_library
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      redirect_after_write(write_placements)
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      result = SectionImages.remove(
        images_recording: images_recording,
        placement_recording: placement_recording,
        actor: presskits_actor
      )
      redirect_after_write(result, removed: true)
    end

    private

    def write_placements
      SectionImages.write(
        images_recording: images_recording,
        actor: presskits_actor,
        library_recording: selected_library,
        file: params[:file],
        signed_blob_id: params[:signed_blob_id],
        attachment_recordings: selected_attachments
      )
    end

    def redirect_after_write(result, removed: false)
      path = section_edit_path
      if result.success?
        redirect_to path, notice: write_notice(result, removed: removed)
      else
        redirect_to picker_or_edit_path, alert: result.error.presence || "Could not update those photos."
      end
    end

    def write_notice(result, removed:)
      return "Photo removed from the kit. It is still in the library." if removed
      return "Photos added." if Array(result.placed).many?
      return "That photo is already in this section." if result.skipped.to_i.positive? && Array(result.placed).empty?

      "Photo added."
    end

    def picker_or_edit_path
      uploaded_file.present? || params[:signed_blob_id].present? ? section_edit_path : picker_path
    end

    def picker_libraries
      return [] unless defined?(RecordingStudioAttachable)

      RecordingStudioAttachable::Placements.picker_libraries_for(images_recording)
    end

    def selected_library
      libraries = picker_libraries
      return if libraries.empty?

      libraries.find { |library| library.id.to_s == params[:library_id].to_s } || libraries.first
    end

    def selected_attachments
      ids = Array(params[:attachment_recording_ids]).map(&:presence).compact
      return [] if ids.empty?

      RecordingStudio::Recording.where(id: ids)
    end

    def uploaded_file
      params[:file]
    end

    def placement_recording
      return @placement_recording if defined?(@placement_recording)

      @placement_recording = images_recording.recordings_query(
        include_children: true,
        type: "RecordingStudioAttachable::Placement",
        parent_id: images_recording.id
      ).where(trashed_at: nil).find_by(id: params[:id])
    end

    def images_recording
      return @images_recording if defined?(@images_recording)

      content = KitQuery.section_content(section_recording)
      @images_recording = content if content&.recordable.is_a?(Images)
    end

    def section_recording
      @section_recording ||= KitQuery.section_for(@press_kit_recording, params[:section_id])
    end

    def require_images_section!
      return if section_recording && images_recording

      head :not_found
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def picker_path
      press_kit_section_library_images_path(@press_kit_recording, section_recording)
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
