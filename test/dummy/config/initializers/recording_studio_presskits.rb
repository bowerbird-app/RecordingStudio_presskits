# frozen_string_literal: true

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
  config.excluded_picker_types = ["FakeBlock"]
  config.sign_in_path = "/users/sign_in"
  config.registration_path = "/users/sign_up"
  config.site_name = "Harbour Studio"
end

RecordingStudioPresskits.register_section(
  "FakeBlock",
  component: "FakeBlock::Component",
  prepare: lambda { |recordable, title: nil, **|
    recordable.title = title.presence || recordable.title.presence || "Block"
  }
)
