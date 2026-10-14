# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ControllerAuthTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "controller-auth-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Controller Auth Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "engine application controller includes ControllerAuth with presskits prefix" do
    controller = RecordingStudioPresskits::ApplicationController

    assert_includes controller.ancestors, RecordingStudioAccessible::ControllerAuth
    assert controller.private_method_defined?(:authenticate_presskits_actor!)
    assert controller.private_method_defined?(:presskits_actor)
    assert controller.private_method_defined?(:set_presskits_current_actor)
    assert controller.private_method_defined?(:current_presskits_root)
    assert controller.private_method_defined?(:authorize_recording!)
    assert controller.private_method_defined?(:require_root!)
    assert_includes controller._helper_methods.map(&:to_s), "current_presskits_root"
    assert_equal "presskits", controller.recording_studio_auth_prefix
    assert controller.recording_studio_auth_options.frozen?
  end

  test "generated auth helpers are not controller actions" do
    methods = RecordingStudioPresskits::ApplicationController.action_methods

    refute_includes methods, "authenticate_presskits_actor!"
    refute_includes methods, "presskits_actor"
    refute_includes methods, "set_presskits_current_actor"
    refute_includes methods, "current_presskits_root"
    refute_includes methods, "authorize_recording!"
    refute_includes methods, "require_root!"
  end

  test "press kits index authenticates through ControllerAuth and sets Current.actor" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path

    assert_response :success
    assert_equal @user, Current.actor
  end

  test "press kits index still redirects unauthenticated visitors to sign in" do
    get recording_studio_presskits.press_kits_path

    assert_redirected_to new_user_session_path
  end

  test "press kits index forbids a signed-in actor without access" do
    outsider = User.create!(
      email: "controller-auth-denied-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path

    assert_response :forbidden
  end

  test "require_root! forbids when the actor has no available root" do
    rootless = User.create!(
      email: "controller-auth-rootless-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in rootless

    get recording_studio_presskits.press_kits_path

    assert_response :forbidden
  end

  test "kit edit authorizes through ControllerAuth for an editor" do
    kit = @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Auth kit" }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)

    assert_response :success
  end

  test "kit edit forbids a viewer who cannot edit" do
    kit = @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "View only kit" }
    viewer = User.create!(
      email: "controller-auth-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    grant = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: viewer,
      role: :view,
      manager_actor: @user
    )
    raise grant.error if grant.failure?

    sign_in viewer
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)

    assert_response :forbidden
  end

  private

  def switch_to_root(root_recording)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: recording_studio_presskits.press_kits_path
      }
    }
    follow_redirect! if response.redirect?
  end
end
