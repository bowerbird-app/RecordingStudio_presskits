# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]

  # Presskits sets a default for :"presskits.kit_download" after initialize
  # (public, plus any registered custom audiences). Hosts overwrite that hash
  # to change who may download a live kit. See the Presskits README.
end
