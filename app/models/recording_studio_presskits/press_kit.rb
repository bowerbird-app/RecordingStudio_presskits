# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit < ApplicationRecord
    self.table_name = "recording_studio_press_kits"

    recording_studio_recordable label: "Press kit",
                                root: false,
                                allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

    include RecordingStudio::Capabilities::Orderable.to
    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Duplicatable.to(
      suffix: " (Copy)",
      exclude_children: []
    )
    include RecordingStudio::Capabilities::Publishable.to(
      public_controller: "recording_studio_presskits/public_press_kits",
      public_action: :show,
      public_layout: "recording_studio/default_layout"
    )

    validates :title, presence: true
  end
end
