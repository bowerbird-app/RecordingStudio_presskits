# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ListsInstallTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "lists-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Lists Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "lists is enabled on the workspace root and the screens mount at /lists" do
    assert RecordingStudio.capability_enabled?(:lists, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:lists, for: "Folder")
    refute RecordingStudio.capability_enabled?(:lists, for: "Page")
    refute RecordingStudio.capability_enabled?(:lists, for: "Showcase")
    refute RecordingStudio.capability_enabled?(:lists, for: "AdminRoot")
    assert_equal [ "Workspace" ], RecordingStudio.allowed_parent_types_for("RecordingStudio::Lists::List")
    assert_equal [ "RecordingStudio::Lists::List" ],
                 RecordingStudio.allowed_parent_types_for("RecordingStudio::Lists::ListItem")
    assert_includes RecordingStudio.configuration.recordable_types, "RecordingStudio::Lists::List"
    assert_includes RecordingStudio.configuration.recordable_types, "RecordingStudio::Lists::ListItem"

    sign_in @user
    switch_to_root(@root)

    list = RecordingStudio::Lists.create(parent: @root, name: "Reading", description: "Magazines", actor: @user)

    assert_equal @root, list.parent_recording
    assert_equal "Reading", list.recordable.name

    get "/lists"

    assert_response :success
    assert_rounded_default_layout
    assert_select "h1", text: "Lists"
    assert_includes response.body, "Reading"
    assert_includes response.body, "controllers/recording_studio_lists/add_to_list_controller"
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
