# frozen_string_literal: true

require "test_helper"

class RecordingStudioPresskitsTest < ActiveSupport::TestCase
  test "dummy app loads root switchable config and controller support" do
    assert_equal [ "all_workspaces" ], RecordingStudioRootSwitchable.configuration.scopes.keys
    assert_equal :application_layout, RecordingStudioRootSwitchable.configuration.layout
    assert_includes ApplicationController.ancestors, RecordingStudio::RootSwitchable::ControllerSupport
    assert_includes ApplicationController.ancestors, RecordingStudio::UsesDefaultLayout
  end

  test "dummy tailwind includes default layout and flatpack classes" do
    css = Rails.root.join("app/assets/builds/tailwind.css").read

    assert_includes css, "max-w-6xl"
    assert_includes css, "button-ghost-background-color"
    assert_includes css, "surface-subtle-background-color"
  end

  test "dummy app validates recordable declarations" do
    assert RecordingStudio.validate_recordable_declarations!
    assert_equal [ "AdminRoot", "Workspace" ].sort, RecordingStudio.root_recordable_types.sort
    assert_equal [ "Workspace", "Folder" ], RecordingStudio.allowed_parent_types_for("Page")
    assert_equal [ "Workspace" ], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::PressKit")
    assert_equal [ "RecordingStudioPresskits::PressKit" ], RecordingStudio.allowed_parent_types_for("FakeBlock")
    assert_equal "Press kit", RecordingStudio.recordable_type_label(RecordingStudioPresskits::PressKit)
    assert_includes RecordingStudioPresskits.picker_types, "FakeBlock"
  end

  test "dummy app schema keeps accessible grants and press kits" do
    connection = ActiveRecord::Base.connection

    assert connection.column_exists?(:recording_studio_recordings, :root_recording_id)
    assert connection.table_exists?(:recording_studio_accesses)
    assert connection.table_exists?(:recording_studio_press_kits)
    assert connection.table_exists?(:admin_roots)
    assert connection.column_exists?(:recording_studio_press_kits, :title)
    refute connection.column_exists?(:recording_studio_press_kits, :updated_at)
    assert connection.table_exists?(:fake_blocks)
    assert connection.column_exists?(:fake_blocks, :title)
    refute connection.column_exists?(:fake_blocks, :updated_at)
    assert connection.column_exists?(:recording_studio_recordings, :recording_studio_orderable_position)
    assert connection.column_exists?(:recording_studio_recordings, :trashed_at)
    assert connection.column_exists?(:recording_studio_recordings, :trash_root)
    assert connection.table_exists?(:recording_studio_trashable_retention_settings)
    refute connection.table_exists?(:recording_studio_access_boundaries)
    refute connection.table_exists?(:recording_studio_device_sessions)
  end

  test "dummy seeds use hierarchy idempotently and restore current actor" do
    Current.actor = nil

    load Rails.root.join("db/seeds.rb").to_s

    workspace = Workspace.find_by!(name: "Studio Workspace")
    accessible_workspace = Workspace.find_by!(name: "Client Workspace")
    private_workspace = Workspace.find_by!(name: "Private Workspace")
    folder = Folder.find_by!(name: "Product Docs")
    page = Page.find_by!(title: "Getting Started")
    press_kit = RecordingStudioPresskits::PressKit.find_by!(title: "Spring launch")
    hero = FakeBlock.find_by!(title: "Hero")
    quotes = FakeBlock.find_by!(title: "Quotes")
    admin_root = AdminRoot.find_by!(name: "Admin")
    root_recording = RecordingStudio::Recording.find_by!(recordable: workspace)
    accessible_root_recording = RecordingStudio::Recording.find_by!(recordable: accessible_workspace)
    private_root_recording = RecordingStudio::Recording.find_by!(recordable: private_workspace)
    admin_root_recording = RecordingStudio::Recording.find_by!(recordable: admin_root)
    folder_recording = RecordingStudio::Recording.find_by!(recordable: folder)
    page_recording = RecordingStudio::Recording.find_by!(recordable: page)
    press_kit_recording = RecordingStudio::Recording.find_by!(recordable: press_kit)
    hero_recording = RecordingStudio::Recording.find_by!(recordable: hero)
    quotes_recording = RecordingStudio::Recording.find_by!(recordable: quotes)

    assert_nil Current.actor
    assert_nil root_recording.parent_recording_id
    assert_nil accessible_root_recording.parent_recording_id
    assert_nil private_root_recording.parent_recording_id
    assert_nil admin_root_recording.parent_recording_id
    assert RecordingStudioAccessible.authorized?(
      actor: User.find_by!(email: "admin@admin.com"),
      recording: admin_root_recording,
      role: :view
    )
    assert_equal root_recording, folder_recording.parent_recording
    assert_equal root_recording, folder_recording.root_recording
    assert_equal folder_recording, page_recording.parent_recording
    assert_equal root_recording, page_recording.root_recording
    assert_equal root_recording, press_kit_recording.parent_recording
    assert_equal root_recording, press_kit_recording.root_recording
    assert_equal press_kit_recording, hero_recording.parent_recording
    assert_equal root_recording, hero_recording.root_recording
    assert_equal press_kit_recording, quotes_recording.parent_recording
    assert_equal root_recording, quotes_recording.root_recording
    assert_equal 3, Workspace.count
    assert_operator RecordingStudioPresskits::PressKit.count, :>=, 1
    assert_operator FakeBlock.count, :>=, 2

    assert_no_difference -> { User.count } do
      assert_no_difference -> { RecordingStudio::Recording.count } do
        assert_no_difference -> { RecordingStudioPresskits::PressKit.count } do
          assert_no_difference -> { FakeBlock.count } do
            load Rails.root.join("db/seeds.rb").to_s
          end
        end
      end
    end
    assert_nil Current.actor
  ensure
    Current.actor = nil
  end

  test "workspace opts into accessible and orderable without enabling mixins on the wrong types" do
    workspace_source = File.read(Rails.root.join("app/models/workspace.rb"))

    refute_includes workspace_source, "Capabilities::Example"
    refute_includes workspace_source, "if defined?(RecordingStudioAccessible)"
    refute_includes workspace_source, ".with("
    assert RecordingStudio.capability_enabled?(:accessible, for: Workspace)
    assert RecordingStudio.capability_enabled?(:orderable, for: Workspace)
    assert RecordingStudio.capability_enabled?(:orderable, for: RecordingStudioPresskits::PressKit)
    assert RecordingStudio.capability_enabled?(:trashable, for: RecordingStudioPresskits::PressKit)
    assert RecordingStudio.capability_enabled?(:trashable, for: FakeBlock)
    assert RecordingStudio.capability_enabled?(:duplicatable, for: RecordingStudioPresskits::PressKit)
    refute RecordingStudio.capability_enabled?(:accessible, for: Folder)
    refute RecordingStudio.capability_enabled?(:accessible, for: Page)
    refute RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPresskits::PressKit)
    refute RecordingStudio.capability_enabled?(:accessible, for: FakeBlock)
    refute RecordingStudio.capability_enabled?(:orderable, for: FakeBlock)
    refute RecordingStudio.capability_enabled?(:duplicatable, for: FakeBlock)
    refute RecordingStudio.capability_enabled?(:trashable, for: Workspace)
    assert_includes ApplicationController.ancestors, RecordingStudio::UsesDefaultLayout
    assert RecordingStudio.capability_enabled?(:accessible, for: AdminRoot)
  end

  test "accessible grant on the workspace root covers a nested press kit" do
    user = User.create!(
      email: "kit-access-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    workspace = Workspace.create!(name: "Access Workspace #{SecureRandom.hex(4)}")
    root_recording = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: root_recording,
      actor: user
    )
    raise result.error if result.failure?

    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Spring launch"
    end

    assert RecordingStudioAccessible.authorized?(actor: user, recording: root_recording, role: :admin)
    assert RecordingStudioAccessible.authorized?(actor: user, recording: kit_recording, role: :view)
    assert RecordingStudioAccessible.authorized?(actor: user, recording: kit_recording, role: :admin)
  end

  test "dummy admin root enables the press kits section" do
    source = File.read(Rails.root.join("app/models/admin_root.rb"))

    assert_includes source, "include RecordingStudioAdmin::AllowsAdminSections"
    assert_includes source, "section :press_kits"
    assert RecordingStudio.capability_enabled?(:accessible, for: AdminRoot)
  end

  test "dummy default layout puts rounded on html without dropping UsesDefaultLayout" do
    layout = File.read(Rails.root.join("app/views/layouts/recording_studio/default_layout.html.erb"))
    controller = File.read(Rails.root.join("app/controllers/application_controller.rb"))

    assert_includes layout, '<html data-theme="rounded">'
    assert_includes layout, "page_nav_options[:anchor_href]"
    assert_includes layout, "anchor_tooltip:"
    refute_includes layout, "page_nav_options[:anchor_url]"
    assert_includes controller, "include RecordingStudio::UsesDefaultLayout"
    assert_includes controller, '"recording_studio/default_layout"'
    refute File.exist?(Rails.root.join("app/views/home/index.html.erb"))
    refute File.exist?(Rails.root.join("app/controllers/home_controller.rb"))
  end
end
