class FakeBlock < ApplicationRecord
  recording_studio_recordable label: "Fake block",
                              root: false,
                              allowed_parent_types: ["RecordingStudioPresskits::PressKit"]

  include RecordingStudio::Capabilities::Trashable.to

  validates :title, presence: true
end
