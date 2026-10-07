# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return unless accepted_section_type?

      recording = add_section
      redirect_to edit_press_kit_section_path(@press_kit_recording, recording), notice: "Section added."
    rescue ArgumentError, NameError, ActiveRecord::RecordInvalid
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

      child = section_recording
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

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:id])
    end

    def revise_section
      headings = heading_params
      attributes = content_attributes
      return nothing_to_save if headings.nil? && attributes.nil?

      save_section(headings, attributes)
      redirect_to section_edit_path, notice: "Saved."
    end

    def nothing_to_save
      redirect_to section_edit_path, alert: "Nothing to save here yet."
    end

    def save_section(headings, attributes)
      SectionComposer.update!(
        section_recording: @section_recording,
        root_recording: current_presskits_root,
        headings: headings,
        content_attributes: attributes
      )
    end

    def heading_params
      return unless params.key?(:kit_section)

      params.require(:kit_section).permit(:title, :subtitle).to_h.symbolize_keys
    end

    def content_attributes
      content = KitQuery.section_content(@section_recording)
      editor = content && RecordingStudioPresskits.section_editor_for(content)
      return if editor.blank? || editor.permitted_attributes.blank?
      return unless params.key?(editor.param_key)

      params.require(editor.param_key).permit(*editor.permitted_attributes).to_h
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

    def add_section
      RecordingStudioPresskits.create_section!(
        press_kit_recording: @press_kit_recording,
        content_type: section_type_name,
        actor: presskits_actor,
        title: params[:title],
        subtitle: params[:subtitle]
      )
    end
  end
end
