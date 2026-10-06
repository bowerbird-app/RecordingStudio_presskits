# frozen_string_literal: true

module RecordingStudioPresskits
  class OrdersController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      apply_reorder
      return if performed?

      redirect_to edit_press_kit_path(@press_kit_recording), notice: "Order saved."
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def apply_reorder
      return reorder_by_ids if ordered_recording_ids.present?
      return reorder_by_move if move_child.present?

      redirect_to edit_press_kit_path(@press_kit_recording), alert: "Nothing to reorder."
    end

    def reorder_by_ids
      save_section_order(ordered_recording_ids)
    end

    def reorder_by_move
      save_section_order(moved_section_ids(move_child))
    end

    def save_section_order(section_ids)
      @press_kit_recording.recording_studio_orderable_reorder!(
        ordered_recording_ids: KitQuery.child_ids_with_section_order(@press_kit_recording, section_ids),
        actor: presskits_actor
      )
    end

    def moved_section_ids(child)
      ids = section_sibling_ids
      ids.delete(child.id.to_s)
      ids.insert(insertion_index(ids), child.id.to_s)
    end

    def section_sibling_ids
      @press_kit_recording.recording_studio_orderable_children.filter_map do |recording|
        recording.id.to_s if RecordingStudioPresskits.section?(recording)
      end
    end

    def ordered_recording_ids
      Array(params[:ordered_recording_ids]).presence
    end

    def move_child
      child_id = params[:recording_id].presence || params[:id].presence
      return if child_id.blank?

      KitQuery.live_child(@press_kit_recording, child_id)
    end

    def move_index
      value = params[:to_index].presence || params[:position].presence
      Integer(value, exception: false) || 0
    end

    def insertion_index(sibling_ids)
      return index_after(sibling_ids, params[:after_recording_id]) if params[:after_recording_id].present?
      return index_before(sibling_ids, params[:before_recording_id]) if params[:before_recording_id].present?

      move_index
    end

    def index_after(sibling_ids, recording_id)
      anchor = sibling_ids.index(recording_id.to_s)
      anchor ? anchor + 1 : sibling_ids.length
    end

    def index_before(sibling_ids, recording_id)
      sibling_ids.index(recording_id.to_s) || 0
    end
  end
end
