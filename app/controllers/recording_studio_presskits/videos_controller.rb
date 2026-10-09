# frozen_string_literal: true

module RecordingStudioPresskits
  class VideosController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @video = RecordingStudioVideo::Video.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_video
      redirect_to video_edit_path(recording), notice: "Video added."
    rescue ActiveRecord::RecordInvalid => e
      @video = invalid_video(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless video_recording

      @video = video_recording.recordable
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless video_recording

      revise_video
      respond_with_preview_or_redirect(html_redirect: video_edit_path(video_recording), notice: "Saved.")
    rescue ActiveRecord::RecordInvalid => e
      @video = invalid_video(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless video_recording

      trash_video
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :video_section_recording

    def add_video
      video_section_recording.record(
        RecordingStudioVideo::Video,
        parent_recording: video_section_recording,
        actor: presskits_actor
      ) { |video| video.assign_attributes(video_params) }
    end

    def revise_video
      current_presskits_root.revise(video_recording, actor: presskits_actor) do |video|
        video.assign_attributes(video_params)
      end
    end

    def trash_video
      video_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def video_params
      params.require(:video).permit(:title, :url, :description)
    end

    def invalid_video(error)
      record = error.record
      return record if record.is_a?(RecordingStudioVideo::Video)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(RecordingStudioVideo::Video)

      RecordingStudioVideo::Video.new(video_params)
    end

    def video_recording
      return @video_recording if defined?(@video_recording)

      @video_recording = find_video(params[:id])
    end

    def find_video(id)
      VideoSection.active_videos(video_section_recording).find_by(id: id)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def video_edit_path(recording)
      edit_press_kit_section_video_path(@press_kit_recording, section_recording, recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @video_section_recording = KitQuery.section_content(@section_recording)
      return if @video_section_recording&.recordable.is_a?(VideoSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
