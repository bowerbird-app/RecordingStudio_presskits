# frozen_string_literal: true

module RecordingStudioPresskits
  class KitQuery
    class << self
      def for_root(root_recording)
        return RecordingStudio::Recording.none if root_recording.blank?

        live_kits
          .where(root_recording: root_recording, parent_recording: root_recording)
          .includes(:recordable)
          .reorder(:recording_studio_orderable_position, :created_at, :id)
      end

      def live_kits
        RecordingStudio::Recording.recording_studio_trashable_active
                                  .where(recordable_type: RecordingStudioPresskits.press_kit_type_name)
                                  .includes(:recordable)
      end

      def published_kits
        live_kits.where(recordable_id: RecordingStudioPresskits::PressKit.indexable.select(:id))
                 .includes(:recordable)
                 .reorder(created_at: :desc)
      end

      def unpublished_kits
        live_kits.where.not(recordable_id: RecordingStudioPresskits::PressKit.published.select(:id))
                 .includes(:recordable)
                 .reorder(created_at: :desc)
      end

      def live_children(parent_recording)
        return RecordingStudio::Recording.none if parent_recording.blank?

        types = RecordingStudioPresskits.section_types
        return RecordingStudio::Recording.none if types.empty?

        parent_recording.recording_studio_orderable_children.merge(
          RecordingStudio::Recording.recording_studio_trashable_active
        ).where(recordable_type: types)
      end

      # Section ids in the requested order, with every other child left in its slot.
      def child_ids_with_section_order(parent_recording, section_ids)
        children = parent_recording.recording_studio_orderable_children.to_a
        queue = ordered_sections(children, section_ids)

        children.map { |child| child_id_in_section_order(child, queue) }
      end

      def ordered_sections(children, section_ids)
        sections = children.select { |child| RecordingStudioPresskits.section?(child) }
        sections_by_id = sections.index_by { |child| child.id.to_s }
        requested = requested_section_ids(section_ids, sections_by_id)
        requested.map { |id| sections_by_id.fetch(id) } + sections.reject { |child| requested.include?(child.id.to_s) }
      end

      def requested_section_ids(section_ids, sections_by_id)
        Array(section_ids).map(&:to_s).uniq.select { |id| sections_by_id.key?(id) }
      end

      def child_id_in_section_order(child, queue)
        return queue.shift.id.to_s if RecordingStudioPresskits.section?(child)

        child.id.to_s
      end

      def live_child(parent_recording, id)
        return if id.blank?

        live_children(parent_recording).find_by(id: id)
      end
    end
  end
end
