# frozen_string_literal: true

module RecordingStudioPresskits
  class FactsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @fact = Fact.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_fact
      redirect_to fact_edit_path(recording), notice: "Fact added."
    rescue ActiveRecord::RecordInvalid => e
      @fact = invalid_fact(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      head :not_found unless fact_recording
      @fact = fact_recording.recordable if fact_recording
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless fact_recording

      revise_fact
      redirect_to fact_edit_path(fact_recording), notice: "Saved."
    rescue ActiveRecord::RecordInvalid => e
      @fact = invalid_fact(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless fact_recording

      trash_fact
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :facts_section_recording

    def add_fact
      facts_section_recording.record(Fact, parent_recording: facts_section_recording) do |fact|
        fact.assign_attributes(fact_params)
      end
    end

    def revise_fact
      current_presskits_root.revise(fact_recording) do |recordable|
        recordable.assign_attributes(fact_params)
      end
    end

    def trash_fact
      fact_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def fact_params
      params.require(:fact).permit(:label, :value, :unit, :description, :source_url, :as_of_date)
    end

    def invalid_fact(error)
      record = error.record
      return record if record.is_a?(Fact)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(Fact)

      Fact.new(fact_params)
    end

    def fact_recording
      return @fact_recording if defined?(@fact_recording)

      @fact_recording = find_fact(params[:id])
    end

    def find_fact(id)
      facts_section_recording.child_recordings.where(fact_scope).find_by(id: id)
    end

    def fact_scope
      { trashed_at: nil, recordable_type: "RecordingStudioPresskits::Fact" }
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def fact_edit_path(recording)
      edit_press_kit_section_fact_path(@press_kit_recording, section_recording, recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @facts_section_recording = KitQuery.section_content(@section_recording)
      return if @facts_section_recording&.recordable.is_a?(FactsSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
