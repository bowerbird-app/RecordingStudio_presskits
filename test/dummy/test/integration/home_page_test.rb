# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class HomePageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "home shows a nested press kit and fake block in the dummy outline" do
    user = User.find_or_create_by!(email: "home-outline-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    previous_actor = Current.actor
    Current.actor = user

    workspace = Workspace.create!(name: "Outline Workspace")
    root_recording = RecordingStudio.root_recording_for(workspace)
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Spring launch"
    end
    kit_recording.record(FakeBlock, parent_recording: kit_recording) do |fake_block|
      fake_block.title = "Hero"
    end

    sign_in user

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: "/"
      }
    }

    follow_redirect!

    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_select "body[data-theme='rounded']", count: 1
    assert_includes response.body, "/assets/tailwind"
    assert_includes response.body, "/assets/flat_pack/variables"
    assert_includes response.body, "Press kit: Spring launch"
    assert_includes response.body, "Fake block: Hero"
    assert_includes response.body, "Workspace: Outline Workspace"
  ensure
    Current.actor = previous_actor
  end
end
