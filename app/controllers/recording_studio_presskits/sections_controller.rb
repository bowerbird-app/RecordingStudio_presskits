# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return unless accepted_section_type?

      add_section(section_type_name)
      redirect_to edit_press_kit_path(@press_kit_recording), notice: "Section added. Drag to change the order."
    rescue NameError, ActiveRecord::RecordInvalid
      redirect_to edit_press_kit_path(@press_kit_recording), alert: "Could not add that section. Try another."
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      child = KitQuery.live_child(@press_kit_recording, params[:id])
      unless child.respond_to?(:recording_studio_trashable_trash!)
        redirect_to edit_press_kit_path(@press_kit_recording), alert: "That section is already gone."
        return
      end

      child.recording_studio_trashable_trash!(actor: presskits_actor)
      redirect_to edit_press_kit_path(@press_kit_recording), notice: "That section is gone."
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def section_type_name
      params[:type].presence || params[:id].presence || params.dig(:section, :type).presence
    end

    def accepted_section_type?
      return true if RecordingStudioPresskits.picker_types.include?(section_type_name)

      redirect_to edit_press_kit_path(@press_kit_recording), alert: "That section isn't on the list."
      false
    end

    def add_section(type_name)
      klass = type_name.constantize
      title = params[:title].presence || RecordingStudio.recordable_type_label(type_name)

      @press_kit_recording.record(klass, parent_recording: @press_kit_recording) do |recordable|
        recordable.title = title if recordable.respond_to?(:title=)
      end
    end
  end
end
