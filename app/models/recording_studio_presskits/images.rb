# frozen_string_literal: true

module RecordingStudioPresskits
  class Images < ApplicationRecord
    self.table_name = "recording_studio_images"

    recording_studio_recordable label: "Images",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::KitSection"]

    def self.section_menu_icon
      "photo"
    end

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: [:image],
      max_file_size: 10.megabytes,
      max_file_count: 50,
      auth_roles: { remove: :edit }
    )
    include RecordingStudio::Capabilities::Orderable.to(
      allows: ["RecordingStudioAttachable::Attachment"]
    )
    include RecordingStudio::Capabilities::Downloadable.to(
      source: :manifest,
      format: :zip,
      action: ImagesDownload::ACTION,
      export_scope: ImagesDownload::EXPORT_SCOPE
    )

    def downloadable_manifest
      ImagesArchive.files_for(RecordingStudio::Recording.find_by(recordable: self))
    end

    def downloadable_available_for?(actor:, action:)
      return false if action.present? && action.to_sym != ImagesDownload::ACTION

      recording = RecordingStudio::Recording.find_by(recordable: self)
      kit = KitDownloadGate.kit_for(recording)
      return false unless kit.respond_to?(:currently_published?) && kit.currently_published?

      Visibility.presentation_for(actor: actor, kit: kit, purpose: :public) == :full
    end

    # Downloadable names the zip from this. The stem is the section heading.
    # Duplicatable writes a prefixed name on anything that answers `name`.
    # The copy still reads the heading, so the writer does nothing.
    def name
      ImagesArchive.stem_for(RecordingStudio::Recording.find_by(recordable: self))
    end

    def name=(_value)
      nil
    end
  end
end
