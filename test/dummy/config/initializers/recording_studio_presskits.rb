# frozen_string_literal: true

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
end

RecordingStudioPresskits.register_section_component("FakeBlock", "FakeBlock::Component")
