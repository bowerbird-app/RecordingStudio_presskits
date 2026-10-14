# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @stat = Stat.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_stat
      redirect_to stat_edit_path(recording), notice: "Stat added."
    rescue ActiveRecord::RecordInvalid => e
      @stat = invalid_stat(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      head :not_found unless stat_recording
      @stat = stat_recording.recordable if stat_recording
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless stat_recording

      revise_stat
      respond_with_preview_or_redirect(html_redirect: stat_edit_path(stat_recording), notice: "Saved.")
    rescue ActiveRecord::RecordInvalid => e
      @stat = invalid_stat(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless stat_recording

      trash_stat
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :stats_section_recording

    def add_stat
      stats_section_recording.record(Stat, parent_recording: stats_section_recording) do |stat|
        stat.assign_attributes(stat_params)
      end
    end

    def revise_stat
      current_presskits_root.revise(stat_recording) do |recordable|
        recordable.assign_attributes(stat_params)
      end
    end

    def trash_stat
      stat_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def stat_params
      params.require(:stat).permit(:label, :value, :unit, :description)
    end

    def invalid_stat(error)
      record = error.record
      return record if record.is_a?(Stat)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(Stat)

      Stat.new(stat_params)
    end

    def stat_recording
      return @stat_recording if defined?(@stat_recording)

      @stat_recording = find_stat(params[:id])
    end

    def find_stat(id)
      stats_section_recording.child_recordings.where(stat_scope).find_by(id: id)
    end

    def stat_scope
      { trashed_at: nil, recordable_type: "RecordingStudioPresskits::Stat" }
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def stat_edit_path(recording)
      edit_press_kit_section_stat_path(@press_kit_recording, section_recording, recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @stats_section_recording = KitQuery.section_content(@section_recording)
      return if @stats_section_recording&.recordable.is_a?(StatsSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
