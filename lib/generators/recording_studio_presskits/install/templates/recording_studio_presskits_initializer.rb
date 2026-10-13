# frozen_string_literal: true

RecordingStudioPresskits.configure do |config|
  # Host names the parent root type. Dummy and the generator default stay Workspace.
  config.parent_root_type = "<%= parent_root_type %>"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user

  # Sign-in path on limited previews when the audience is signed_in.
  # config.sign_in_path = "/users/sign_in"
  # Registration path for the preview Create account button. Leave blank to hide it.
  # config.registration_path = "/users/sign_up"
  # Site name in "You must be signed in to {site name}…". Falls back to i18n, then the Rails app name.
  # config.site_name = "Harbour Studio"

  # Icons on the Downloads audience RadioGroup. Keys are audience names.
  # Missing keys fall back to i18n `recording_studio_presskits.downloads.audience_icons`,
  # then globe-alt / user / lock-closed, then user-group for custom audiences.
  # config.download_audience_icons = {
  #   public: "globe-alt",
  #   signed_in: "user",
  #   granted: "lock-closed"
  # }
end
