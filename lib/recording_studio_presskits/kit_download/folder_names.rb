# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    # Downloadable flattens every zip entry with File.basename. A Files section
    # needs one folder, named from the section title. This keeps a single
    # already-safe "folder/file" name and still flattens everything else.
    module FolderNames
      def self.install!
        singleton = RecordingStudioDownloadable::Filename.singleton_class
        return if singleton.ancestors.include?(self)

        singleton.prepend(self)
      end

      def unique_in(filename, used)
        folder, base = split_entry(filename)
        return super if folder.nil?

        remember_unique(folder, base, used)
      end

      private

      def remember_unique(folder, base, used)
        candidate = "#{folder}/#{base}"
        sequence = 2
        while used.include?(candidate.downcase)
          candidate = "#{folder}/#{numbered(base, sequence)}"
          sequence += 1
        end

        used << candidate.downcase
        candidate
      end

      def numbered(base, sequence)
        extension = File.extname(base)
        "#{File.basename(base, extension)}-#{sequence}#{extension}"
      end

      def split_entry(filename)
        raw = filename.to_s.tr("\\", "/")
        return if raw.count("/") != 1
        return if raw.include?("..")

        folder, base = raw.split("/", 2)
        safe_folder = RecordingStudioDownloadable::Filename.sanitize(folder)
        safe_base = RecordingStudioDownloadable::Filename.sanitize(base)
        return unless safe_folder == folder && safe_base == base
        return if safe_folder.blank? || safe_base.blank?

        [safe_folder, safe_base]
      end
    end
  end
end
