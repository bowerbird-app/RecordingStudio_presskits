# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionsController < ApplicationController # rubocop:disable Metrics/ClassLength
    before_action :require_root!
    before_action :set_press_kit

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return unless accepted_section_type?

      @section_recording = add_section
      @section_recordings = KitQuery.sections_for(@press_kit_recording)
      respond_to_editor_change(:create, html_redirect: editor_path(highlight: @section_recording.id),
                                        notice: "Section added.")
    rescue ArgumentError, NameError, ActiveRecord::RecordInvalid
      redirect_to editor_path, alert: "Could not add that section. Try another."
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      head(:not_found) unless section_recording
    end

    def heading
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
      render update_error_template, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      child = section_recording
      unless child.respond_to?(:recording_studio_trashable_trash!)
        redirect_to editor_path, alert: "That section is already gone."
        return
      end

      child.recording_studio_trashable_trash!(actor: presskits_actor)
      @section_recordings = KitQuery.sections_for(@press_kit_recording)
      respond_to_editor_change(:destroy, html_redirect: editor_path, notice: "That section is gone.")
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
      @section_recordings = KitQuery.sections_for(@press_kit_recording)
      respond_to_editor_change(:update, html_redirect: after_save_path, notice: "Saved.")
    end

    def nothing_to_save
      redirect_to after_save_path, alert: "Nothing to save here yet."
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

    def after_save_path
      return heading_press_kit_section_path(@press_kit_recording, @section_recording) if heading_only_save?

      section_edit_path
    end

    def heading_only_save?
      params.key?(:kit_section) && content_attributes.nil?
    end

    def update_error_template
      params.key?(:kit_section) ? :heading : :edit
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, @section_recording)
    end

    def editor_path(highlight: nil)
      edit_press_kit_path(@press_kit_recording, highlight: highlight)
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

      redirect_to editor_path, alert: "That section isn't on the list."
      false
    end

    def add_section
      recording = RecordingStudioPresskits.create_section!(
        press_kit_recording: @press_kit_recording,
        content_type: section_type_name,
        actor: presskits_actor,
        title: section_create_title,
        subtitle: params[:subtitle]
      )
      @after_recording_id = params[:after_recording_id].presence
      position_section(recording)
      recording
    end

    def section_create_title
      params[:title].presence || RecordingStudio.recordable_type_label(section_type_name)
    end

    def position_section(recording) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      after_id = params[:after_recording_id].presence
      return if after_id.blank?

      ids = KitQuery.sections_for(@press_kit_recording).map { |section| section.id.to_s }
      ids.delete(recording.id.to_s)
      index = ids.index(after_id.to_s)
      if index
        ids.insert(index + 1, recording.id.to_s)
      else
        ids << recording.id.to_s
      end

      @press_kit_recording.recording_studio_orderable_reorder!(
        ordered_recording_ids: ids,
        actor: presskits_actor
      )
    end

    def respond_to_editor_change(template, html_redirect:, notice:)
      respond_to do |format|
        format.turbo_stream do
          if from_kit_editor?
            render template
          else
            redirect_to html_redirect, notice: notice
          end
        end
        format.html { redirect_to html_redirect, notice: notice }
      end
    end

    def from_kit_editor?
      super || request.referer.to_s.include?("/press_kits/#{@press_kit_recording.id}/edit")
    end
  end
end
