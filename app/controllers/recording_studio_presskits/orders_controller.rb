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
      @press_kit_recording.recording_studio_orderable_reorder!(
        ordered_recording_ids: ordered_recording_ids,
        actor: presskits_actor
      )
    end

    def reorder_by_move
      @press_kit_recording.recording_studio_orderable_move!(
        move_child,
        to_index: move_index,
        actor: presskits_actor
      )
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
  end
end
