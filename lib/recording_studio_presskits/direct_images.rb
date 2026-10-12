# frozen_string_literal: true

module RecordingStudioPresskits
  class DirectImages
    class << self
      def list(recording)
        return [] if recording.blank? || !recording.respond_to?(:id)
        return [] unless defined?(RecordingStudioAttachable::Queries::ForRecording)

        sort_by_order(recording, image_recordings(recording))
      rescue StandardError
        []
      end

      def url_for(item, helpers:)
        file = item&.recordable&.try(:file)
        return unless file&.attached?

        helpers.main_app.url_for(file)
      rescue StandardError
        nil
      end

      def alt_for(item, fallback: "Image")
        attachment = item&.recordable
        attachment&.try(:alt_text).presence || attachment&.try(:name).presence || fallback
      end

      def enabled?(recording)
        return false if recording.blank?
        return false unless defined?(RecordingStudio)

        type_name = recording.respond_to?(:recordable_type) ? recording.recordable_type : nil
        type_name.present? && RecordingStudio.capability_enabled?(:attachable, for: type_name)
      rescue StandardError
        false
      end

      private

      def image_recordings(recording)
        RecordingStudioAttachable::Queries::ForRecording.new(
          recording: recording,
          scope: :direct,
          kind: :images,
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
