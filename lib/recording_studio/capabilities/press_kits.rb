# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module PressKits
      def self.to
        RecordingStudio::Capabilities.include_for(:press_kits)
      end
    end
  end
end

RecordingStudio.register_capability(
  :press_kits,
  source: "recording_studio_presskits",
  child_recordables: ["RecordingStudioPresskits::PressKit"]
)
