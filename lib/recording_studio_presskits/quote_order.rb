# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteOrder
    def initialize(section_recording, params, recordable_type: "RecordingStudioPresskits::Quote")
      @section_recording = section_recording
      @params = params
      @recordable_type = recordable_type
    end

    def apply(actor)
      return reorder_by_ids(actor) if ordered_recording_ids.present?
      return reorder_by_move(actor) if move_child.present?

      false
    end

    private

    def reorder_by_ids(actor)
      section_recording.recording_studio_orderable_reorder!(
        ordered_recording_ids: ordered_recording_ids,
        actor: actor
      )
    end

    def reorder_by_move(actor)
      child = move_child
      section_recording.recording_studio_orderable_move!(
        child,
        to_index: insertion_index(child),
        actor: actor
      )
    end

    def ordered_recording_ids
      Array(params[:ordered_recording_ids]).presence
    end

    def move_child
      child_id = params[:recording_id].presence || params[:id].presence
      return if child_id.blank?

      find_quote(child_id)
    end

    def find_quote(id)
      section_recording.child_recordings.where(quote_scope).find_by(id: id)
    end

    def quote_scope
      { trashed_at: nil, recordable_type: recordable_type }
    end

    def insertion_index(child)
      sibling_ids = sibling_ids_without(child)
      return index_after(sibling_ids, params[:after_recording_id]) if params[:after_recording_id].present?
      return index_before(sibling_ids, params[:before_recording_id]) if params[:before_recording_id].present?

      move_index
    end

    def sibling_ids_without(child)
      ids = section_recording.recording_studio_orderable_children.map { |recording| recording.id.to_s }
      ids.delete(child.id.to_s)
      ids
    end

    def index_after(sibling_ids, recording_id)
      anchor = sibling_ids.index(recording_id.to_s)
      anchor ? anchor + 1 : sibling_ids.length
    end

    def index_before(sibling_ids, recording_id)
      sibling_ids.index(recording_id.to_s) || 0
    end

    def move_index
      value = params[:to_index].presence || params[:position].presence
      Integer(value, exception: false) || 0
    end

    attr_reader :section_recording, :params, :recordable_type
  end
end
