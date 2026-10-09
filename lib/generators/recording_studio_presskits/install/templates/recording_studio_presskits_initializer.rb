# frozen_string_literal: true

RecordingStudioPresskits.configure do |config|
  # Host names the parent root type. Dummy and the generator default stay Workspace.
  config.parent_root_type = "<%= parent_root_type %>"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user

  # Host-nominated kit cover colours. Use :any to allow any hex.
  # config.cover_colors = %w[#1F2937 #7C3AED #DB2777 #059669 #D97706]
  # config.cover_colors = :any
  # config.default_cover_color = "#1F2937"
end
