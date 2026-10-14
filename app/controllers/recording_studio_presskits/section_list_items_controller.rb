# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionListItemsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_lines
    end

    private

    attr_reader :section_recording, :list_section_recording

    def save_lines
      @list_item_batch = ListItemBatch.from_rows(line_rows)
      saved = ListItemBatch::Sync.call(
        section_recording: list_section_recording,
        root_recording: current_presskits_root,
        drafts: @list_item_batch.lines,
        actor: presskits_actor
      )
      return render_invalid unless saved

      respond_with_preview_or_redirect(html_redirect: section_edit_path, notice: "Saved.")
    end

    def render_invalid
      render template: "recording_studio_presskits/sections/edit",
             status: :unprocessable_entity,
             formats: [:html]
    end

    def line_rows
      nested = permitted_lines[:lines_attributes]
      return [] if nested.blank?

      nested.values
    end

    def permitted_lines
      bag = params[:list_lines]
      return ActionController::Parameters.new if bag.blank?

      bag.permit(lines_attributes: %i[id icon key value _destroy])
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @list_section_recording = KitQuery.section_content(@section_recording)
      head :not_found unless @list_section_recording&.recordable.is_a?(ListSection)
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      head :not_found if @press_kit_recording.blank?
    end
  end
end
