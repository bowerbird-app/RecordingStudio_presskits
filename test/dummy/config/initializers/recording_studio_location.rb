# frozen_string_literal: true

RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder::Fake.demo
end
