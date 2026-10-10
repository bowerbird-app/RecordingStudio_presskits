# frozen_string_literal: true

module RecordingStudioPresskits
  class CoverImage
    PLACEMENT_TYPE = "RecordingStudioAttachable::Placement"

    Resolved = Struct.new(:placement_recording, :attachment_recording, :attachment, keyword_init: true)

    class << self
      def resolved(recording)
        return if recording.blank?
        return unless defined?(RecordingStudioAttachable)
        return unless recording.respond_to?(:library_placements)

        recording.library_placements.first
      rescue StandardError
        nil
      end

      def url_for(recording, helpers:)
        attachment = resolved(recording)&.attachment
        file = attachment&.file
        return unless file&.attached?

        helpers.main_app.url_for(file)
      rescue StandardError
        nil
      end

      def alt_for(recording)
        item = resolved(recording)
        attachment = item&.attachment
        attachment&.alt_text.presence || attachment&.name.presence ||
          item&.attachment_recording&.name.presence || "Cover"
      end

      def enabled?(recording)
        return false if recording.blank?
        return false unless defined?(RecordingStudioAttachable)
        return false unless defined?(RecordingStudio)

        RecordingStudio.capability_enabled?(:library_placement, for: recording.recordable_type)
      rescue StandardError
        false
      end
    end
  end
end
