# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class HomePageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "signed-in root is the press kit index with default layout" do
    user = User.find_or_create_by!(email: "home-outline-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    previous_actor = Current.actor
    Current.actor = user

    workspace = Workspace.create!(name: "Outline Workspace")
    root_recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: root_recording,
      actor: user
    )
    raise result.error if result.failure?

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
        return_to: "/recording_studio_presskits"
      }
    }

    follow_redirect!

    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    refute_includes response.body, "Dummy host"
  ensure
    Current.actor = previous_actor
  end
end
