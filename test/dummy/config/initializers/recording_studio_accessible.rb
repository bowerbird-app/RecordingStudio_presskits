# frozen_string_literal: true

unless RecordingStudioAccessible.registered_audience?(:"presskits.verified_journalist")
  RecordingStudioAccessible.register_audience(
    :"presskits.verified_journalist",
    label_key: "recording_studio_presskits.audiences.verified_journalist"
  ) do |actor:, recording:, context:| # rubocop:disable Lint/UnusedBlockArgument
    next false unless actor.present?

    if actor.respond_to?(:verified_journalist?)
      actor.verified_journalist?
    else
      actor.respond_to?(:email) && actor.email.to_s.end_with?("@journalists.example")
    end
  end
end

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]

  # Presskits sets a default for :"presskits.kit_download" after initialize
  # (public, plus any registered custom audiences). Hosts overwrite that hash
  # to change who may download a live kit. See the Presskits README.
end
