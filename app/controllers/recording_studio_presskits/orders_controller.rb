# frozen_string_literal: true

module RecordingStudioPresskits
  class OrdersController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      respond_to_reorder(persist_order)
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def persist_order
      if ordered_recording_ids.present?
        reorder_by_ids
        :saved
      elsif (child = move_child)
        reorder_by_move(child)
        :saved
      end
    end

    def reorder_by_ids
      @press_kit_recording.recording_studio_orderable_reorder!(
        ordered_recording_ids: ordered_ids_with_cover_placements,
        actor: presskits_actor
      )
    end

    def ordered_ids_with_cover_placements
      ids = Array(ordered_recording_ids).map(&:to_s)
      ids + (cover_placement_ids - ids)
    end

    def cover_placement_ids
      @press_kit_recording.recording_studio_orderable_children.filter_map do |recording|
        recording.id.to_s if recording.recordable_type == "RecordingStudioAttachable::Placement"
      end
    end

    def reorder_by_move(child)
      @press_kit_recording.recording_studio_orderable_move!(
        child,
        to_index: move_to_index(child),
        actor: presskits_actor
      )
    end

    def respond_to_reorder(result)
      saved = result == :saved
      if json_request?
        return render json: { ok: saved }, status: (saved ? :ok : :unprocessable_entity)
      end

      redirect_to edit_press_kit_path(@press_kit_recording),
                  **(saved ? { notice: "Order saved." } : { alert: "Nothing to reorder." })
    end

    def json_request?
      request.format.json? || request.headers["Accept"].to_s.include?("application/json")
    end

    def move_child
      child_id = params[:recording_id].presence || params[:moving_recording_id].presence || params[:id].presence
      return if child_id.blank?

      KitQuery.section_for(@press_kit_recording, child_id)
    end

    def move_to_index(child)
      return target_position_index if params[:target_position].present?
      return neighbor_index(child) if neighbor_move?

      move_index
    end

    def neighbor_move?
      params[:after_recording_id].present? || params[:before_recording_id].present?
    end

    def neighbor_index(child)
      ids = section_sibling_ids
      ids.delete(child.id.to_s)
      return index_after(ids, params[:after_recording_id]) if params[:after_recording_id].present?

      index_before(ids, params[:before_recording_id])
    end

    def section_sibling_ids
      @press_kit_recording.recording_studio_orderable_children.filter_map do |recording|
        recording.id.to_s if RecordingStudioPresskits.section?(recording)
      end
    end

    def ordered_recording_ids
      Array(params[:ordered_recording_ids]).presence
    end

    def target_position_index
      position = Integer(params[:target_position], exception: false)
      return 0 if position.nil?

      [position - 1, 0].max
    end

    def move_index
      value = params[:to_index].presence || params[:position].presence
      Integer(value, exception: false) || 0
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
