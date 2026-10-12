# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitParentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "showcase-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Showcase Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?

    @showcase = @root.record(Showcase) { |row| row.name = "Launch week" }
    @nested = @root.record(RecordingStudioPresskits::PressKit, parent_recording: @showcase) do |press_kit|
      press_kit.title = "Nested launch"
    end
    @direct = @root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Direct launch"
    end
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "index editor and preview find a kit under a showcase" do
    assert_equal @showcase, @nested.parent_recording
    assert_equal @root, @nested.root_recording
    assert_includes RecordingStudioPresskits::KitQuery.for_root(@root), @nested
    assert_includes RecordingStudioPresskits::KitQuery.for_root(@root), @direct

    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_includes response.body, "Nested launch"
    assert_includes response.body, "Direct launch"

    get recording_studio_presskits.edit_press_kit_path(@nested)
    assert_response :success
    assert_includes response.body, "Nested launch"

    get recording_studio_presskits.preview_press_kit_path(@nested)
    assert_response :success
    assert_includes response.body, "Nested launch"
  end

  private

  def switch_to_root(root)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root.id,
        return_to: "/recording_studio_presskits"
      }
    }
    follow_redirect! if response.redirect?
  end
end
