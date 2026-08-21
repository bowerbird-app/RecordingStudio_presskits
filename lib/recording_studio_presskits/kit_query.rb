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

      def live_children(parent_recording)
        return RecordingStudio::Recording.none if parent_recording.blank?

        parent_recording.recording_studio_orderable_children.merge(
          RecordingStudio::Recording.recording_studio_trashable_active
        )
      end

      def live_child(parent_recording, id)
        return if id.blank?

        live_children(parent_recording).find_by(id: id)
      end
    end
  end
end
