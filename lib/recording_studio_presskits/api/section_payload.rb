# frozen_string_literal: true

require "recording_studio_presskits/api/video_payload"

module RecordingStudioPresskits
  module Api
    class SectionPayload
      def self.for(recordable, recording = nil)
        recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
        content = recording && KitQuery.section_content(recording)
        payload = headings(recordable, content)
        return payload unless content&.recordable_type == VideoSection.name

        payload.merge(videos: VideoPayload.for_recording(content))
      end

      def self.headings(recordable, content)
        {
          title: recordable.title,
          subtitle: recordable.subtitle,
          content_type: content&.recordable_type,
          content_id: content&.id
        }
      end
      private_class_method :headings
    end
  end
end
