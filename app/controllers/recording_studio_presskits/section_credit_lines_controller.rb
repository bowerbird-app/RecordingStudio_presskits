# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionCreditLinesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_lines
      respond_with_preview_or_redirect(html_redirect: section_edit_path, notice: "Saved.")
    rescue ArgumentError
      redirect_to section_edit_path, alert: "That credit is not in this workspace."
    end

    private

    attr_reader :section_recording, :credits_section_recording

    def save_lines
      CreditLineBatch::Sync.call(
        section_recording: credits_section_recording,
        root_recording: current_presskits_root,
        rows: line_rows,
        actor: presskits_actor
      )
    end

    def line_rows
      nested = permitted_lines[:credit_lines_attributes]
      return [] if nested.blank?

      nested.values
    end

    def permitted_lines
      bag = params[:credit_lines]
      return ActionController::Parameters.new if bag.blank?

      bag.permit(credit_lines_attributes: %i[id credit_recording_id role _destroy])
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
