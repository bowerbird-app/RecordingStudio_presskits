# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit < ApplicationRecord
    self.table_name = "recording_studio_press_kits"

    recording_studio_recordable label: "Press kit",
                                root: false,
                                allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

    include RecordingStudio::Capabilities::Orderable.to(
      allows: ["RecordingStudioPresskits::KitSection"]
    )
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: [:image],
      max_file_size: 10.megabytes,
      max_file_count: 1,
      auth_roles: { remove: :edit }
    )
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
    include RecordingStudio::Capabilities::Downloadable.to(
      source: :manifest,
      format: :zip,
      action: KitDownload::ACTION,
      export_scope: KitDownload::EXPORT_SCOPE
    )
    include RecordingStudio::Capabilities::Location.to
    include BrandAttributes

    RecordingStudio.enable_capability(:action_audiences, on: self) if defined?(RecordingStudio)

    def downloadable_manifest
      KitDownload.manifest_for(RecordingStudio::Recording.find_by(recordable: self))
    end

    def downloadable_available_for?(actor:, action:) # rubocop:disable Lint/UnusedMethodArgument
      return false if action.present? && action.to_sym != KitDownload::ACTION

      recording = RecordingStudio::Recording.find_by(recordable: self)
      recording.respond_to?(:currently_published?) && recording.currently_published?
    end

    # The header is the kit itself. Title is required. The short description
    # can be blank. It is not a child, so it cannot be trashed or reordered.
    SHORT_DESCRIPTION_LIMIT = 280
    SUBTITLE_LIMIT = 120

    validates :title, presence: true
    validates :description, length: { maximum: SHORT_DESCRIPTION_LIMIT }, allow_nil: true
    validates :subtitle, length: { maximum: SUBTITLE_LIMIT }, allow_nil: true

    before_validation :normalize_header

    private

    def normalize_header
      self.description = description.to_s.strip.presence
      self.subtitle = subtitle.to_s.strip.presence
    end
  end
end
