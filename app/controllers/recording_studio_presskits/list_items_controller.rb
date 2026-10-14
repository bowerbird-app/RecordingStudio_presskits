# frozen_string_literal: true

module RecordingStudioPresskits
  class ListItemsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def new
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @item = ListItem.new
    end

    def create
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      recording = add_item
      redirect_to item_edit_path(recording), notice: "Item added."
    rescue ActiveRecord::RecordInvalid => e
      @item = invalid_item(e)
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      head :not_found unless item_recording
      @item = item_recording.recordable if item_recording
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless item_recording

      revise_item
      respond_with_preview_or_redirect(html_redirect: item_edit_path(item_recording), notice: "Saved.")
    rescue ActiveRecord::RecordInvalid => e
      @item = invalid_item(e)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless item_recording

      trash_item
      redirect_to section_edit_path
    end

    private

    attr_reader :section_recording, :list_section_recording

    def add_item
      list_section_recording.record(ListItem, parent_recording: list_section_recording) do |item|
        item.assign_attributes(item_params)
      end
    end

    def revise_item
      current_presskits_root.revise(item_recording) do |recordable|
        recordable.assign_attributes(item_params)
      end
    end

    def trash_item
      item_recording.recording_studio_trashable_trash!(actor: presskits_actor)
    end

    def item_params
      params.require(:list_item).permit(:icon, :key, :value)
    end

    def invalid_item(error)
      record = error.record
      return record if record.is_a?(ListItem)

      recordable = record.recordable if record.is_a?(RecordingStudio::Recording)
      return recordable if recordable.is_a?(ListItem)

      ListItem.new(item_params)
    end

    def item_recording
      return @item_recording if defined?(@item_recording)

      @item_recording = find_item(params[:id])
    end

    def find_item(id)
      list_section_recording.child_recordings
                            .where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                            .where(recordable_type: "RecordingStudioPresskits::ListItem")
                            .find_by(id: id)
    end

    def section_edit_path
      edit_press_kit_section_path(@press_kit_recording, section_recording)
    end

    def item_edit_path(recording)
      edit_press_kit_section_list_item_path(@press_kit_recording, section_recording, recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.section_for(@press_kit_recording, params[:section_id])
      @list_section_recording = KitQuery.section_content(@section_recording)
      return if @list_section_recording&.recordable.is_a?(ListSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
