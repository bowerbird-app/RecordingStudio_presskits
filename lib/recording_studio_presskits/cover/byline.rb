# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    module Byline
      def company_recording
        Company.recording_for(@recording)
      end

      def company_name
        Company.name_for(@recording)
      end

      def location_recordable
        KitLocation.recordable_for(@recording)
      end
    end
  end
end
