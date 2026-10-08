# frozen_string_literal: true

require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/location_payload"

module RecordingStudioPresskits
  module Api
    class SectionPayload
      def self.for(recordable, recording = nil)
        recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
        content = recording && KitQuery.section_content(recording)
        payload = headings(recordable, content)
        return payload.merge(videos: VideoPayload.for_recording(content)) if content&.recordable_type == VideoSection.name
        return payload.merge(location: LocationPayload.for(content.recordable)) if LocationContent.type?(content)

        payload
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
