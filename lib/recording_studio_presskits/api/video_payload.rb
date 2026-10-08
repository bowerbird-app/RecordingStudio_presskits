# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class VideoPayload
      KEYS = %i[title url description provider canonical_url content_type].freeze

      def self.for(recordable)
        KEYS.index_with { |name| recordable.public_send(name) }
      end

      def self.for_recording(recording)
        VideoSection.active_videos(recording).map { |child| VideoPayload.for(child.recordable) }
      end
    end
  end
end
