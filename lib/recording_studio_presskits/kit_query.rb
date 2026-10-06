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

      def sections_for(press_kit_recording)
        return RecordingStudio::Recording.none if press_kit_recording.blank?

        ordered_active_children(press_kit_recording).where(recordable_type: KitSection.name)
      end

      def section_for(press_kit_recording, id)
        return if id.blank?

        sections_for(press_kit_recording).find_by(id: id)
      end

      def section_content(section_recording)
        return if section_recording.blank?

        children = active_children(section_recording)
        registered = children.where(recordable_type: RecordingStudioPresskits.section_types)
        registered.first || children.first
      end

      private

      def ordered_active_children(parent_recording)
        parent_recording.recording_studio_orderable_children.merge(
          RecordingStudio::Recording.recording_studio_trashable_active
        )
      end

      def active_children(parent_recording)
        parent_recording.child_recordings
                        .merge(RecordingStudio::Recording.recording_studio_trashable_active)
                        .order(:recording_studio_orderable_position, :created_at, :id)
      end
    end
  end
end
