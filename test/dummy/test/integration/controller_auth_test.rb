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

  test "verify_authenticity_token runs before ControllerAuth before_actions" do
    filters = RecordingStudioPresskits::ApplicationController
               ._process_action_callbacks
               .select { |callback| callback.kind == :before }
               .map(&:filter)

    verify_at = filters.index(:verify_authenticity_token)
    authenticate_at = filters.index(:authenticate_presskits_actor!)
    set_actor_at = filters.index(:set_presskits_current_actor)

    assert verify_at, "expected :verify_authenticity_token in before filters"
    assert authenticate_at, "expected :authenticate_presskits_actor! in before filters"
    assert set_actor_at, "expected :set_presskits_current_actor in before filters"
    assert_operator verify_at, :<, authenticate_at
    assert_operator verify_at, :<, set_actor_at
  end

  test "signed-out write with a bad CSRF token returns 422 before auth redirect" do
    with_forgery_protection do
      assert_no_difference -> { RecordingStudio::Recording.where(recordable_type: "RecordingStudioPresskits::PressKit").count } do
        post recording_studio_presskits.press_kits_path,
             params: {
               authenticity_token: "bad-token",
               press_kit: { title: "CSRF should block this" }
             }
      end
    end

    assert_response :unprocessable_entity
    refute_response_redirected_to_sign_in
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

  test "falls back to Current.actor when current_actor_method is unset" do
    assert_equal :current_then_method,
                 RecordingStudioPresskits::ApplicationController.recording_studio_auth_options[:actor_resolution]

    with_current_actor_method(nil) do
      assert_authorized_via_planted_current_actor
    end
  end

  test "falls back to Current.actor when current_actor_method is undefined" do
    with_current_actor_method(:not_a_real_actor_method) do
      assert_authorized_via_planted_current_actor
    end
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

  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def refute_response_redirected_to_sign_in
    refute_equal new_user_session_path, response.redirect_url.to_s.sub(%r{\Ahttps?://[^/]+}, "")
    refute_includes [301, 302, 303, 307, 401], response.status
  end

  def with_current_actor_method(method_name)
    previous = RecordingStudioPresskits.configuration.current_actor_method
    RecordingStudioPresskits.configuration.current_actor_method = method_name
    yield
  ensure
    RecordingStudioPresskits.configuration.current_actor_method = previous
  end

  # CurrentAttributes resets between requests, so plant inside the request
  # before ControllerAuth resolves the actor (same shape as Accessible's demos).
  def assert_authorized_via_planted_current_actor
    stranger = User.create!(
      email: "controller-auth-planted-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in @user
    switch_to_root(@root)
    sign_in stranger

    plant_current_actor_during_request(@user) do
      get recording_studio_presskits.press_kits_path
    end

    assert_response :success
    assert_equal @user, Current.actor
  end

  def plant_current_actor_during_request(actor)
    controller = RecordingStudioPresskits::ApplicationController
    planted = actor
    controller.class_eval do
      prepend_before_action :plant_controller_auth_current_actor_for_test

      define_method(:plant_controller_auth_current_actor_for_test) do
        Current.actor = planted
      end
      private :plant_controller_auth_current_actor_for_test
    end

    yield
  ensure
    controller.class_eval do
      skip_before_action :plant_controller_auth_current_actor_for_test, raise: false
      remove_method :plant_controller_auth_current_actor_for_test if method_defined?(:plant_controller_auth_current_actor_for_test) ||
                                                                    private_method_defined?(:plant_controller_auth_current_actor_for_test)
    end
  end
end
