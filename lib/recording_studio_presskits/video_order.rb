# frozen_string_literal: true

module RecordingStudioPresskits
  class VideoOrder < QuoteOrder
    def initialize(section_recording, params)
      super(section_recording, params, recordable_type: "RecordingStudioVideo::Video")
    end
  end
end
