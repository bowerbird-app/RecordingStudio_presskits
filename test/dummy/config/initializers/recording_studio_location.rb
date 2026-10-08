# frozen_string_literal: true

RecordingStudioLocation.configure do |config|
  # Builds a Google adapter when Rails credentials (or ENV) supply provider + api_key.
  # Unset credentials keep this nil, so Location never contacts a network service.
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
end
