class Showcase < ApplicationRecord
  recording_studio_recordable label: "Showcase",
                              root: false,
                              allowed_parent_types: ["Workspace"]

  include RecordingStudio::Capabilities::PressKits.to
end
