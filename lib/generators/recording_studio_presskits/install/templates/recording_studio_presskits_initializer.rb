# frozen_string_literal: true

RecordingStudioPresskits.configure do |config|
  # Host names the parent root type. Dummy and the generator default stay Workspace.
  config.parent_root_type = "<%= parent_root_type %>"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
end
