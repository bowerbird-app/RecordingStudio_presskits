# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class AdminPressKitsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "admin-ui-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Admin UI Workspace #{SecureRandom.hex(4)}")
    @admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    owner = User.create!(
      email: "kit-owner-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = owner
    @workspace_root = RecordingStudio.root_recording_for(@workspace)
    @admin_root_recording = RecordingStudio.root_recording_for(@admin_root)

    owner_grant = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: @workspace_root,
      actor: owner
    )
    raise owner_grant.error if owner_grant.failure?

    @workspace_root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Spring launch"
    end

    Current.actor = @user
    admin_grant = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: @admin_root_recording,
      actor: @user
    )
    raise admin_grant.error if admin_grant.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "admin list widget includes the spring launch kit" do
    sign_in @user
    switch_to_admin_root

    get "/admin"
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Press kits"
    assert_includes response.body, "/admin/sections/press_kits/widgets/widgets.press_kits.list"
    refute_includes response.body, "Dummy host"

    get "/admin/sections/press_kits/widgets/widgets.press_kits.list", params: {
      widget_usage_index: 0,
      widget_view_variant: "__default__"
    }
    assert_response :success
    assert_includes response.body, "Spring launch"
  end

  test "admin denies missing access with 403" do
    outsider = User.create!(
      email: "admin-denied-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider

    get "/admin"
    assert_response :forbidden
  end

  test "unauthenticated admin visitors are not shown the list" do
    get "/admin"
    assert_includes [401, 302], response.status
    refute_includes response.body, "Spring launch" if response.redirect?
  end

  private

  def switch_to_admin_root
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @admin_root_recording.id,
        return_to: "/admin"
      }
    }
    follow_redirect! if response.redirect?
  end
end
