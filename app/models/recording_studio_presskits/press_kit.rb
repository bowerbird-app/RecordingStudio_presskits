# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit < ApplicationRecord
    self.table_name = "recording_studio_press_kits"

    recording_studio_recordable label: "Press kit",
                                root: false,
                                allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

    include RecordingStudio::Capabilities::Orderable.to(
      allows: [
        "RecordingStudioPresskits::KitSection",
        "RecordingStudioAttachable::Placement"
      ]
    )
    include RecordingStudio::Capabilities::LibraryPlacement.to
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
    include RecordingStudio::Capabilities::Location.to
    include CoverAttributes

    RecordingStudio.enable_capability(:action_audiences, on: self)

    # The header is the kit itself. Title is required. The short description
    # can be blank. It is not a child, so it cannot be trashed or reordered.
    SHORT_DESCRIPTION_LIMIT = 280
    COVER_STYLES = %w[color].freeze
    AUTO_COVER_TEXT = CoverAttributes::AUTO_COVER_TEXT

    validates :title, presence: true
    validates :description, length: { maximum: SHORT_DESCRIPTION_LIMIT }, allow_nil: true
    validates :cover_style, inclusion: { in: COVER_STYLES }, allow_nil: true

    before_validation :normalize_header

    private

    def normalize_header
      self.description = description.to_s.strip.presence
      normalize_cover
    end
  end
end
