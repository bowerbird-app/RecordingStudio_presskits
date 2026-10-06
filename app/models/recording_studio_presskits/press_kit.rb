# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit < ApplicationRecord
    self.table_name = "recording_studio_press_kits"

    recording_studio_recordable label: "Press kit",
                                root: false,
                                allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

    include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPresskits::KitSection"])
    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Duplicatable.to(
      suffix: " (Copy)",
      exclude_children: []
    )
    include RecordingStudio::Capabilities::Publishable.to(
      public_controller: "recording_studio_presskits/public_press_kits",
      public_action: :show,
      public_layout: "recording_studio_presskits/blank"
    )

    # The header is the kit itself. Title is required. The short description
    # can be blank. It is not a child, so it cannot be trashed or reordered.
    SHORT_DESCRIPTION_LIMIT = 280

    validates :title, presence: true
    validates :description, length: { maximum: SHORT_DESCRIPTION_LIMIT }, allow_nil: true

    before_validation :clear_blank_description

    private

    def clear_blank_description
      self.description = description.to_s.strip.presence
    end
  end
end
