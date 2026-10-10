# frozen_string_literal: true

RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "AdminRoot",
    "RecordingStudioPresskits::PressKit",
    "RecordingStudioPresskits::KitSection",
    "RecordingStudioPresskits::Text",
    "RecordingStudioPresskits::Images",
    "RecordingStudioPresskits::QuoteSection",
    "RecordingStudioPresskits::Quote",
    "RecordingStudioPresskits::FactsSection",
    "RecordingStudioPresskits::Fact",
    "RecordingStudioPresskits::CreditsSection",
    "RecordingStudioPresskits::Credit",
    "RecordingStudioPresskits::CreditLine",
    "RecordingStudioPresskits::VideoSection",
    "RecordingStudioVideo::Video",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudio::AccessConstraint",
    "RecordingStudio::AccessRule",
    "RecordingStudioAttachable::Attachment",
    "RecordingStudioAttachable::Library",
    "RecordingStudioAttachable::Placement",
    "RecordingStudioCompany::Company",
    "RecordingStudio::Location::Location",
    "FakeBlock"
  ]

  config.require_recordable_declarations = true

  config.app_name = "Press kits" if config.respond_to?(:app_name=)

  config.actor = -> { Current.actor }

  config.event_notifications_enabled = true

  config.idempotency_mode = :return_existing

  config.recordable_dup_strategy = :dup
end
