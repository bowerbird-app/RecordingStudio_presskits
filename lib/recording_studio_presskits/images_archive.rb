# frozen_string_literal: true

module RecordingStudioPresskits
  class ImagesArchive
    def self.files_for(content_recording)
      new(content_recording).files
    end

    def self.filename_for(content_recording)
      "#{stem_for(content_recording)}.zip"
    end

    def self.stem_for(content_recording)
      section = content_recording&.parent_recording
      heading = section.present? ? RecordingStudioPresskits.section_heading(section) : nil
      heading.to_s.parameterize.presence || "images"
    end

    def initialize(content_recording)
      @content_recording = content_recording
    end

    def files
      return [] unless defined?(RecordingStudioDownloadable::DownloadFile)

      names = KitDownload::Filenames.new
      DirectImages.list(@content_recording).filter_map do |item|
        blob = blob_for(item)
        next if blob.blank?

        preferred = item.recordable.try(:original_filename).presence || blob.filename.to_s
        RecordingStudioDownloadable::DownloadFile.from_blob(blob, filename: names.unique(preferred))
      end
    end

    private

    def blob_for(item)
      file = item&.recordable&.try(:file)
      return unless file&.attached?

      file.blob
    rescue StandardError
      nil
    end
  end
end
