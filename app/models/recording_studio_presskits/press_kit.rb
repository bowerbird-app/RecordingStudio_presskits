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
    COVER_STYLES = %w[color].freeze

    validates :title, presence: true
    validates :description, length: { maximum: SHORT_DESCRIPTION_LIMIT }, allow_nil: true
    validates :cover_style, inclusion: { in: COVER_STYLES }, allow_nil: true
    validate :cover_color_must_be_hex
    validate :cover_color_must_be_allowed, if: :validate_cover_palette?

    before_validation :normalize_header

    def resolved_cover_style
      cover_style.presence || "color"
    end

    def resolved_cover_color
      Cover::Hex.normalize(cover_color) || RecordingStudioPresskits.default_cover_color
    end

    def overlay_text_color
      Cover::Contrast.text_on(resolved_cover_color)
    end

    private

    def normalize_header
      self.description = description.to_s.strip.presence
      self.cover_style = cover_style.to_s.strip.presence
      self.cover_color = Cover::Hex.normalize(cover_color)
    end

    def cover_color_must_be_hex
      return if cover_color.blank? || Cover::Hex.valid?(cover_color)

      errors.add(:cover_color, "must be a hex colour")
    end

    def validate_cover_palette?
      cover_color.present? && cover_color_changed? && !RecordingStudioPresskits.any_cover_color?
    end

    def cover_color_must_be_allowed
      return if RecordingStudioPresskits.cover_palette.include?(cover_color)

      errors.add(:cover_color, "must be one of the host colours")
    end
  end
end
