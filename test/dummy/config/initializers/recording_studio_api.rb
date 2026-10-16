# frozen_string_literal: true

# Video registers its API from inside RecordingStudioVideo::Api. That lookup
# only finds Video once the model is already loaded. Require the model before
# the video engine's after_initialize hook. The engine autoloader is not
# managing this file yet. Install the recordable macro first: a test that
# loads this gem before the Rails environment can reach this initializer
# before Recording Studio's own installer runs.
if defined?(RecordingStudio::RecordableDeclarations)
  RecordingStudio::RecordableDeclarations.install_active_record_macro!
end

if defined?(RecordingStudioVideo) && !RecordingStudioVideo.const_defined?(:Video, false)
  video_models = RecordingStudioVideo::Engine.root.join("app/models/recording_studio_video")
  require video_models.join("application_record.rb").to_s
  require video_models.join("video.rb").to_s
end

RecordingStudioApi.configure do |config|
  config.documentation_enabled = true
  config.documentation_access = :public
  config.openapi_title = "Press kits API"
  config.rate_limit_oauth_enabled = false
  config.rate_limit_api_pre_auth_enabled = false
  config.rate_limit_api_enabled = false
  config.rate_limit_fail_closed = false
  config.api_management_authorization_required = false
end

RecordingStudio.enable_capability(:api_access_point, on: "Workspace")
