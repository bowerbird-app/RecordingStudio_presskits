# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteOrdersController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      apply_reorder
    end

    private

    attr_reader :section_recording, :quote_section_recording

    def apply_reorder
      if QuoteOrder.new(quote_section_recording, params).apply(presskits_actor)
        redirect_to section_edit_path, notice: "Order saved."
      else
        redirect_to section_edit_path, alert: "Nothing to reorder."
      end
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @quote_section_recording = KitQuery.section_content(@section_recording)
      return if @quote_section_recording&.recordable.is_a?(QuoteSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
