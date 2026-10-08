# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionCreditsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section
    before_action :set_line, only: %i[edit update destroy]

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @credit = Credit.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      line = place_line
      redirect_to edit_line_path(line), notice: "Credit added." if line
    rescue ActiveRecord::RecordInvalid
      render_invalid_new
    rescue ArgumentError
      head :not_found
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      Credits.revise_role!(
        line_recording: @line_recording,
        root_recording: current_presskits_root,
        role: params.require(:credit_line).permit(:role)[:role]
      )
      redirect_to edit_line_path(@line_recording), notice: "Saved."
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      Credits.remove!(@line_recording, actor: presskits_actor)
      redirect_to section_edit_path, notice: "Removed from this kit."
    end

    private

    attr_reader :section_recording, :credits_section_recording

    def place_line
      credit = chosen_credit or return missing_choice

      Credits.add!(
        credits_section_recording: credits_section_recording,
        credit_recording: credit,
        role: params[:role],
        actor: presskits_actor
      )
    end

    def missing_choice
      redirect_to new_press_kit_section_credit_path(@press_kit_recording, section_recording),
                  alert: "Pick a credit, or add a new one."
      nil
    end

    def chosen_credit
      return credit_in_root if params[:credit_id].present?
      return create_credit if params[:credit].present?

      nil
    end

    def credit_in_root
      Credits.find_for_root(current_presskits_root, params[:credit_id]) || raise(ArgumentError)
    end

    def create_credit
      Credits.create!(
        root_recording: current_presskits_root,
        actor: presskits_actor,
        **new_credit_params.to_h.symbolize_keys
      )
    end

    def render_invalid_new
      @credit = Credit.new(new_credit_params)
      flash.now[:alert] = "Give them a name."
      render :new, status: :unprocessable_entity
    end

    def set_line
      return if performed?

      @line_recording = Credits.find_line(credits_section_recording, params[:id])
      return head :not_found if @line_recording.blank?

      @credit_recording = Credits.credit_for(@line_recording)
    end

    def new_credit_params
      params.fetch(:credit, {}).permit(:name, :url, :usual_role)
    end

    def edit_line_path(recording)
      edit_press_kit_section_credit_path(@press_kit_recording, section_recording, recording)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @credits_section_recording = KitQuery.section_content(@section_recording)
      head :not_found unless @credits_section_recording&.recordable.is_a?(CreditsSection)
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      head :not_found if @press_kit_recording.blank?
    end
  end
end
