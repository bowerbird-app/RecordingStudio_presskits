# frozen_string_literal: true

module RecordingStudioPresskits
  # Attachable's max_file_count is per batch. A Files section holds 10 files in total.
  class FileQuota
    def self.message
      "This section can hold #{Files::MAX_FILES} files. Remove one before adding another."
    end

    module Guard
      def perform
        parent = FileQuota.parent_of(self)
        return super unless FileQuota.applies?(parent)

        parent.with_lock do
          FileQuota.enforce!(parent, incoming: FileQuota.incoming_of(self))
          super
        end
      end
    end

    class << self
      def install!
        return unless defined?(RecordingStudioAttachable::Services::RecordAttachmentUpload)

        service_classes.each do |klass|
          next if klass.nil? || klass.ancestors.include?(Guard)

          klass.prepend(Guard)
        end
      end

      def applies?(recording)
        recording&.recordable.is_a?(Files)
      end

      def enforce!(recording, incoming:)
        return if incoming.to_i <= 0
        return if live_count(recording) + incoming.to_i <= Files::MAX_FILES

        raise ArgumentError, message
      end

      def parent_of(service)
        if service.respond_to?(:parent_recording, true)
          service.send(:parent_recording)
        elsif service.respond_to?(:attachment_recording, true)
          service.send(:attachment_recording)&.parent_recording
        end
      end

      def incoming_of(service)
        return Array(service.send(:attachments)).size if service.respond_to?(:attachments, true)

        1
      end

      def live_count(recording)
        recording.child_recordings
                 .where(recordable_type: "RecordingStudioAttachable::Attachment")
                 .where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                 .count
      end

      private

      def service_classes
        services = RecordingStudioAttachable::Services
        [
          services::ImportAttachmentPayloads,
          services::ImportAttachments,
          services::ImportAttachment,
          services::RecordAttachmentUploads,
          services::RecordAttachmentUpload
        ]
      end
    end
  end
end
