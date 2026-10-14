# frozen_string_literal: true

module RecordingStudioPresskits
  class PodcastsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @podcast = Podcast.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_podcast
      PodcastArtwork.store!(recording, actor: presskits_actor)
      redirect_to podcast_edit_path(recording), notice: "Podcast added."
    rescue ActiveRecord::RecordInvalid => e
      @podcast = invalid_podcast(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless podcast_recording

      @podcast = podcast_recording.recordable
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless podcast_recording

      revise_podcast
      respond_with_preview_or_redirect(html_redirect: podcast_edit_path(podcast_recording), notice: "Saved.")
    rescue ActiveRecord::RecordInvalid => e
      @podcast = invalid_podcast(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless podcast_recording

      trash_podcast
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :podcast_section_recording

    def add_podcast
      podcast_section_recording.record(
        Podcast,
        parent_recording: podcast_section_recording,
        actor: presskits_actor
      ) { |podcast| podcast.assign_attributes(podcast_params) }
    end

    def revise_podcast
      previous = podcast_recording.recordable
      current_presskits_root.revise(podcast_recording, actor: presskits_actor) do |podcast|
        podcast.assign_attributes(podcast_params)
        podcast.artwork_source_url = same_link?(previous) ? previous.artwork_source_url : nil
        PodcastArtwork.carry!(podcast, previous) if same_link?(previous)
      end
      PodcastArtwork.store!(podcast_recording, actor: presskits_actor)
    end

    def same_link?(previous)
      previous.url == podcast_params[:url].to_s.strip
    end

    def trash_podcast
      podcast_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def podcast_params
      params.require(:podcast).permit(:url, :title, :show_name, :aired_on, :duration)
    end

    def invalid_podcast(error)
      record = error.record
      return record if record.is_a?(Podcast)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(Podcast)

      Podcast.new(podcast_params)
    end

    def podcast_recording
      return @podcast_recording if defined?(@podcast_recording)

      @podcast_recording = find_podcast(params[:id])
    end

    def find_podcast(id)
      PodcastSection.active_podcasts(podcast_section_recording).find_by(id: id)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def podcast_edit_path(recording)
      edit_press_kit_section_podcast_path(@press_kit_recording, section_recording, recording)
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
