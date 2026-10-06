# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class SectionPayload
      def self.for(recordable, recording = nil)
        recording ||= RecordingStudio::Recording.find_by(recordable: recordable)
        content = recording && KitQuery.section_content(recording)

        {
          title: recordable.title,
          subtitle: recordable.subtitle,
          content_type: content&.recordable_type,
          content_id: content&.id
        }
      end
    end
  end
end
