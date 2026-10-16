# frozen_string_literal: true

require "recording_studio_presskits/api/video_payload"
require "recording_studio_presskits/api/stat_payload"
require "recording_studio_presskits/api/podcast_payload"
require "recording_studio_presskits/api/location_payload"
require "recording_studio_presskits/api/list_payload"
require "recording_studio_presskits/api/file_payload"
require "recording_studio_presskits/api/image_payload"

module RecordingStudioPresskits
  module Api
    class SectionPayload
      def self.for(recordable, recording = nil, context: nil)
        recording ||= context.recording if context.respond_to?(:recording)
        recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
        return withheld if Exposure.withhold?(context, recording)

        content = recording && KitQuery.section_content(recording)
        payload = headings(recordable, content)
        extras = extras_for(content)
        extras ? payload.merge(extras) : payload
      end

      def self.withheld
        { title: nil, subtitle: nil, content_type: nil, content_id: nil }
      end
      private_class_method :withheld

      EXTRA_FOR = {
        "RecordingStudioPresskits::VideoSection" => ->(content) { { videos: VideoPayload.for_recording(content) } },
        "RecordingStudioPresskits::StatsSection" => ->(content) { StatPayload.for_recording(content) },
        "RecordingStudioPresskits::LocationSection" => lambda { |content|
          { locations: LocationPayload.for_recording(content) }
        },
        "RecordingStudioPresskits::ListSection" => ->(content) { { items: ListPayload.for_recording(content) } },
        "RecordingStudioPresskits::PodcastSection" => lambda { |content|
          { podcasts: PodcastPayload.for_recording(content) }
        },
        "RecordingStudioPresskits::Files" => ->(content) { { files: FilePayload.for_recording(content) } },
        "RecordingStudioPresskits::Images" => ->(content) { { images: ImagePayload.for_recording(content) } }
      }.freeze
      private_constant :EXTRA_FOR

      def self.extras_for(content)
        EXTRA_FOR[content&.recordable_type]&.call(content)
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
