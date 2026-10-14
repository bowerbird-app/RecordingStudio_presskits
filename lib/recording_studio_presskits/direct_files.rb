# frozen_string_literal: true

module RecordingStudioPresskits
  class DirectFiles
    class << self
      def list(recording)
        return [] if recording.blank? || !recording.respond_to?(:id)
        return [] unless defined?(RecordingStudioAttachable::Queries::ForRecording)

        sort_by_order(recording, file_recordings(recording))
      rescue StandardError
        []
      end

      private

      def file_recordings(recording)
        RecordingStudioAttachable::Queries::ForRecording.new(
          recording: recording,
          scope: :direct,
          kind: :files,
          include_trashed: false
        ).unpaged.to_a
      end

      def sort_by_order(recording, items)
        return items unless recording.respond_to?(:recording_studio_orderable_children)

        order = recording.recording_studio_orderable_children.map(&:id)
        items.sort_by.with_index { |item, index| [order.index(item.id) || order.length, index] }
      rescue StandardError
        items
      end
    end
  end
end
