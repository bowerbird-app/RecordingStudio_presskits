# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return unless accepted_section_type?

      recording = add_section(section_type_name)
      redirect_to edit_press_kit_section_path(@press_kit_recording, recording), notice: "Section added."
    rescue NameError, ActiveRecord::RecordInvalid
      redirect_to edit_press_kit_path(@press_kit_recording), alert: "Could not add that section. Try another."
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      head(:not_found) unless section_recording
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless section_recording

      revise_section
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Could not save that section."
      render :edit, status: :unprocessable_entity
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

    def section_recording
      return @section_recording if defined?(@section_recording)

      @section_recording = KitQuery.live_child(@press_kit_recording, params[:id])
    end

    def revise_section
      editor = RecordingStudioPresskits.section_editor_for(@section_recording)
      unless editor
        redirect_to section_edit_path, alert: "Nothing to save here yet."
        return
      end

      attrs = params.require(editor.param_key).permit(editor.permitted_attributes)
      current_presskits_root.revise(@section_recording) { |recordable| recordable.assign_attributes(attrs) }
      redirect_to section_edit_path, notice: "Saved."
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, @section_recording)
    end

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
      label = params[:title].presence || RecordingStudio.recordable_type_label(type_name)

      @press_kit_recording.record(klass, parent_recording: @press_kit_recording) do |recordable|
        assign_section_title(recordable, label)
        assign_opening_body(recordable, label)
      end
    end

    def assign_section_title(recordable, label)
      return unless recordable.respond_to?(:title=)
      return if optional_section_title?(recordable) && params[:title].blank?

      recordable.title = params[:title].presence || label
    end

    def optional_section_title?(recordable)
      recordable.is_a?(Text) || recordable.is_a?(Images)
    end

    def assign_opening_body(recordable, label)
      return unless recordable.respond_to?(:body=)
      return if recordable.body.present?

      recordable.body = params[:body].presence || opening_body_for(recordable) || label
    end

    def opening_body_for(recordable)
      recordable.class.opening_body if recordable.class.respond_to?(:opening_body)
    end
  end
end
