# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    class Manifest
      def self.call(recording)
        new(recording).files
      end

      def initialize(recording)
        @recording = recording
        @names = Filenames.new
      end

      def files
        return [] if @recording.blank? || !defined?(RecordingStudioDownloadable::DownloadFile)

        image_files + [text_file]
      end

      private

      def image_files
        seen = {}
        cover_images(seen) + section_images(seen)
      end

      def cover_images(seen)
        files = []
        append_image(files, CoverImage.resolved(@recording), prefix: "cover", seen: seen)
        files
      end

      def section_images(seen)
        files = []
        visible_image_sections.each do |section|
          prefix = section_prefix(section)
          LibraryImages.resolve(KitQuery.section_content(section)).each do |item|
            append_image(files, item, prefix: prefix, seen: seen)
          end
        end
        files
      end

      def visible_image_sections
        KitQuery.sections_for(@recording).select do |section|
          content = KitQuery.section_content(section)
          content&.recordable.is_a?(Images) &&
            PressKits::SectionFrameComponent.new(section_recording: section).content_visible?
        end
      end

      def append_image(files, item, prefix:, seen:)
        blob = blob_for(item)
        return if blob.blank? || seen[blob.id.to_s]

        seen[blob.id.to_s] = true
        filename = @names.unique([prefix, original_name(item, blob)].compact.join("-"))
        files << RecordingStudioDownloadable::DownloadFile.from_blob(blob, filename: filename)
      end

      def original_name(item, blob)
        item.attachment.try(:original_filename).presence || blob.filename.to_s
      end

      def blob_for(item)
        file = item&.attachment&.file
        return unless file&.attached?

        file.blob
      rescue StandardError
        nil
      end

      def section_prefix(section)
        heading = RecordingStudioPresskits.section_heading(section).to_s
        heading.parameterize.presence || "images"
      end

      def text_file
        RecordingStudioDownloadable::DownloadFile.from_string(
          filename: KitDownload::TEXT_FILENAME,
          content_type: "text/plain",
          content: TextFile.call(@recording)
        )
      end
    end
  end
end
