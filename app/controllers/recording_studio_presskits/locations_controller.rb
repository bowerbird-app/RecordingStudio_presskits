# frozen_string_literal: true

module RecordingStudioPresskits
  class LocationsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @location = RecordingStudio::Location::Location.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_location
      redirect_to location_edit_path(recording), notice: "Location added."
    rescue ActiveRecord::RecordInvalid => e
      @location = invalid_location(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless location_recording

      @location = location_recording.recordable
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless location_recording

      revise_location
      respond_with_preview_or_redirect(html_redirect: location_edit_path(location_recording), notice: "Saved.")
    rescue ActiveRecord::RecordInvalid => e
      @location = invalid_location(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless location_recording

      trash_location
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :location_section_recording

    def add_location
      location_section_recording.record(
        RecordingStudio::Location::Location,
        parent_recording: location_section_recording,
        actor: presskits_actor
      ) { |location| location.assign_attributes(location_params) }
    end

    def revise_location
      current_presskits_root.revise(location_recording, actor: presskits_actor) do |location|
        location.assign_attributes(location_params)
      end
    end

    def trash_location
      location_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def location_params
      params.fetch(:location, {}).permit(*RecordingStudio::Location.permitted_attributes)
    end

    def invalid_location(error)
      record = error.record
      return record if record.is_a?(RecordingStudio::Location::Location)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(RecordingStudio::Location::Location)

      RecordingStudio::Location::Location.new(location_params)
    end

    def location_recording
      return @location_recording if defined?(@location_recording)

      @location_recording = find_location(params[:id])
    end

    def find_location(id)
      LocationSection.active_locations(location_section_recording).find_by(id: id)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def location_edit_path(recording)
      edit_press_kit_section_location_path(@press_kit_recording, section_recording, recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @location_section_recording = KitQuery.section_content(@section_recording)
      return if @location_section_recording&.recordable.is_a?(LocationSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
