# frozen_string_literal: true

RecordingStudioTrashable.configure do |config|
  # Keep Accessible integration enabled when the addon is installed.
  config.use_recording_studio_accessible = true

  # Deny lifecycle actions unless a resolver or Accessible authorizer is available.
  config.allow_unconfigured_authorization = false

  config.authorization_roles = {
    trash: :edit,
    restore: :edit,
    purge: :admin,
    settings: :admin,
    trash_bin: :edit
  }

  config.default_purge_after_days = nil
  config.allow_user_retention_settings = false
end
