class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  RecordingStudio.enable_capability(:accessible, on: self)

  include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::PressKit"])
  include RecordingStudio::Capabilities::Companies.to(allow: :one)
  include RecordingStudio::Capabilities::ImageLibrary.to
end
