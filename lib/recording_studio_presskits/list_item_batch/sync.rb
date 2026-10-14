# frozen_string_literal: true

module RecordingStudioPresskits
  class ListItemBatch
    class Sync
      def self.call(section_recording:, root_recording:, drafts:, actor:)
        new(section_recording:, root_recording:, drafts:, actor:).call
      end

      def initialize(section_recording:, root_recording:, drafts:, actor:)
        @section_recording = section_recording
        @root_recording = root_recording
        @drafts = Array(drafts)
        @actor = actor
      end

      def call
        working = @drafts.reject(&:blank_new_row?)
        return false if working.any? { |draft| invalid?(draft) }

        ActiveRecord::Base.transaction do
          kept = working.filter_map { |draft| write(draft) }
          reorder(kept)
        end
        true
      end

      private

      def invalid?(draft)
        return false if draft.marked_for_destruction?

        probe = ListItem.new(icon: draft.icon, key: draft.key, value: draft.value)
        return false if probe.valid?

        probe.errors.each { |error| draft.errors.add(error.attribute, error.message) }
        true
      end

      def write(draft)
        return remove(draft) if draft.marked_for_destruction?
        return revise(draft) if draft.id.present?

        add(draft)
      end

      def remove(draft)
        recording = find_item(draft.id)
        recording&.recording_studio_trashable_trash!(actor: @actor)
        nil
      end

      def revise(draft)
        recording = find_item(draft.id)
        return if recording.blank?

        @root_recording.revise(recording) do |recordable|
          recordable.assign_attributes(attributes_for(draft))
        end
        recording.id
      end

      def add(draft)
        @section_recording.record(ListItem, parent_recording: @section_recording, actor: @actor) do |item|
          item.assign_attributes(attributes_for(draft))
        end.id
      end

      def attributes_for(draft)
        { icon: draft.icon, key: draft.key, value: draft.value }
      end

      def find_item(id)
        @section_recording.child_recordings.where(item_scope).find_by(id: id)
      end

      def item_scope
        { trashed_at: nil, recordable_type: "RecordingStudioPresskits::ListItem" }
      end

      def reorder(ids)
        current = ListSection.active_items(@section_recording).map { |item| item.id.to_s }
        wanted = ids.map(&:to_s)
        return if current == wanted || current.sort != wanted.sort

        @section_recording.recording_studio_orderable_reorder!(ordered_recording_ids: ids, actor: @actor)
      end
    end
  end
end
