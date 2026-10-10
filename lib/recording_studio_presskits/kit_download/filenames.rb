# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    class Filenames
      def initialize
        @used = {}
      end

      def unique(preferred)
        name = sanitize(preferred)
        key = name.downcase
        return remember(name) unless @used[key]

        stem = File.basename(name, ".*")
        ext = File.extname(name)
        n = 2
        loop do
          candidate = "#{stem}-#{n}#{ext}"
          return remember(candidate) unless @used[candidate.downcase]

          n += 1
        end
      end

      private

      def remember(name)
        @used[name.downcase] = true
        name
      end

      def sanitize(preferred)
        base = preferred.to_s.strip.tr("\\", "/")
        base = File.basename(base)
        base = base.gsub(/[^\w.\-]+/, "-").gsub(/-+/, "-").delete_prefix("-").delete_suffix("-")
        base = "file" if base.blank? || base.start_with?(".")
        base
      end
    end
  end
end
