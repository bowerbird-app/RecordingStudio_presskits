# frozen_string_literal: true

module RecordingStudioPresskits
  class QuotesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      add_quote
      redirect_to section_edit_path, notice: "Quote added."
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless quote_recording

      revise_quote
      redirect_to section_edit_path
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless quote_recording

      trash_quote
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording

    def add_quote
      section_recording.record(Quote, parent_recording: section_recording) do |quote|
        quote.body = ""
        quote.name = ""
      end
    end

    def revise_quote
      current_presskits_root.revise(quote_recording) do |recordable|
        recordable.assign_attributes(quote_params)
      end
    end

    def trash_quote
      quote_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def quote_params
      params.require(:quote).permit(:body, :name, :role, :organisation)
    end

    def quote_recording
      return @quote_recording if defined?(@quote_recording)

      @quote_recording = find_quote(params[:id])
    end

    def find_quote(id)
      section_recording.child_recordings.where(quote_scope).find_by(id: id)
    end

    def quote_scope
      { trashed_at: nil, recordable_type: "RecordingStudioPresskits::Quote" }
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.live_child(@press_kit_recording, params[:section_id])
      return if quote_section?

      head :not_found
    end

    def quote_section?
      @section_recording&.recordable.is_a?(QuoteSection)
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
