# frozen_string_literal: true

module RecordingStudioPresskits
  class LibraryImages
    class << self
      def resolve(recording, include_trashed_images: false)
        return [] if recording.blank?
        return [] unless defined?(RecordingStudioAttachable)
        return [] unless recording.respond_to?(:library_placements)

        RecordingStudioAttachable::Placements.resolve(
          recording,
          include_trashed_images: include_trashed_images
        )
      rescue StandardError
        []
      end

      def url_for(item, helpers:)
        file = item&.attachment&.file
        return unless file&.attached?

        helpers.main_app.url_for(file)
      rescue StandardError
        nil
      end

      def alt_for(item, fallback: "Image")
        attachment = item&.attachment
        attachment&.alt_text.presence || attachment&.name.presence ||
          item&.attachment_recording&.name.presence || fallback
      end

      def enabled?(recording)
        return false if recording.blank?
        return false unless defined?(RecordingStudioAttachable)
        return false unless defined?(RecordingStudio)

        RecordingStudio.capability_enabled?(:library_placement, for: recording.recordable_type)
      rescue StandardError
        false
      end

      def already_placed?(recording, attachment_recording)
        return false if recording.blank? || attachment_recording.blank?

        resolve(recording, include_trashed_images: true).any? do |item|
          item.attachment_recording&.id.to_s == attachment_recording.id.to_s
        end
      end
    end
  end
end
