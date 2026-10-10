# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class LocationPayload
      def self.for(recordable)
        recordable.api_payload
      end

      def self.for_recording(recording)
        LocationSection.active_locations(recording).map { |child| LocationPayload.for(child.recordable) }
      end
    end
  end
end
