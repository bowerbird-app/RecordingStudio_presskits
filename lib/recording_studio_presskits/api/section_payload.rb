# frozen_string_literal: true

require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/fact_payload"
require "recording_studio_presskits/api/location_payload"

module RecordingStudioPresskits
  module Api
    class SectionPayload
      def self.for(recordable, recording = nil)
        recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
        content = recording && KitQuery.section_content(recording)
        payload = headings(recordable, content)
        extras = extras_for(content)
        extras ? payload.merge(extras) : payload
      end

      def self.extras_for(content)
        case content&.recordable_type
        when VideoSection.name
          { videos: VideoPayload.for_recording(content) }
        when FactsSection.name
          FactPayload.for_recording(content)
        when LocationSection.name
          { locations: LocationPayload.for_recording(content) }
        end
      end
      private_class_method :extras_for

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
