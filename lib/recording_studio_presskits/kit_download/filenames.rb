# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    class Filenames
      def initialize
        @used = {}
      end

      def unique(preferred)
        name = sanitize(preferred)
        return remember(name) unless taken?(name)

        uniquify(name)
      end

      # A file inside a section folder. The folder name is already unique.
      # The same filename may exist in another folder.
      def unique_entry(directory, filename)
        folder = sanitize(directory)
        base = sanitize(filename)
        candidate = "#{folder}/#{base}"
        return remember(candidate) unless taken?(candidate)

        uniquify_entry(folder, base)
      end

      private

      def uniquify(name)
        stem = File.basename(name, ".*")
        ext = File.extname(name)
        n = 2
        loop do
          candidate = "#{stem}-#{n}#{ext}"
          return remember(candidate) unless taken?(candidate)

          n += 1
        end
      end

      def uniquify_entry(directory, base)
        stem = File.basename(base, ".*")
        ext = File.extname(base)
        n = 2
        loop do
          candidate = "#{directory}/#{stem}-#{n}#{ext}"
          return remember(candidate) unless taken?(candidate)

          n += 1
        end
      end

      def taken?(name)
        @used[name.downcase]
      end

      def remember(name)
        @used[name.downcase] = true
        name
      end

      def sanitize(preferred)
        base = preferred.to_s.strip.tr("\\", "/")
        base = File.basename(base)
        base = base.gsub(/[^\w.-]+/, "-").gsub(/-+/, "-").delete_prefix("-").delete_suffix("-")
        base = "file" if base.blank? || base.start_with?(".")
        base
      end
    end
  end
end
