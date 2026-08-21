# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class RecordingStudioDeclarationsTest < ActiveSupport::TestCase
  test "dummy recordable declarations validate and expose parent/root introspection" do
    assert RecordingStudio.validate_recordable_declarations!
    assert_equal %w[AdminRoot Workspace], RecordingStudio.root_recordable_types.sort
    assert_equal %w[Workspace Folder], RecordingStudio.allowed_parent_types_for("Folder")
    assert_equal %w[Workspace Folder], RecordingStudio.allowed_parent_types_for(Page)
    assert_equal ["Workspace"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::PressKit")
    assert_equal ["RecordingStudioPresskits::PressKit"], RecordingStudio.allowed_parent_types_for("FakeBlock")
    assert_equal "Press kit", RecordingStudio.recordable_type_label("RecordingStudioPresskits::PressKit")
    assert_equal "RecordingStudioPresskits::PressKit", RecordingStudioPresskits.press_kit_type_name
    refute RecordingStudio.root_allowed?("RecordingStudioPresskits::PressKit")
    refute RecordingStudio.root_allowed?("FakeBlock")
  end

  test "root recordable creates a root recording" do
    workspace = Workspace.create!(name: unique_name("Root Workspace"))

    root_recording = RecordingStudio.root_recording_for(workspace)

    assert_predicate root_recording, :persisted?
    assert_equal workspace, root_recording.recordable
    assert_nil root_recording.parent_recording_id
    assert_equal root_recording.id, root_recording.root_recording_id
  end

  test "allowed child can be recorded under a workspace root" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Child Workspace")))
    folder = Folder.new(name: unique_name("Allowed Folder"))

    event = RecordingStudio.record!(
      action: "created",
      recordable: folder,
      root_recording: root_recording,
      parent_recording: root_recording
    )

    assert_equal folder, event.recording.recordable
    assert_equal root_recording, event.recording.parent_recording
  end

  test "page can be recorded under allowed workspace and folder parents" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Page Workspace")))
    folder_recording = record_child(Folder.new(name: unique_name("Page Folder")), root_recording, root_recording)

    workspace_page_recording = record_child(
      Page.new(title: unique_name("Workspace Page")),
      root_recording,
      root_recording
    )
    folder_page_recording = record_child(Page.new(title: unique_name("Folder Page")), root_recording, folder_recording)

    assert_equal root_recording, workspace_page_recording.parent_recording
    assert_equal folder_recording, folder_page_recording.parent_recording
  end

  test "child recordable cannot be created as a root" do
    folder = Folder.create!(name: unique_name("Root Rejected Folder"))

    assert_raises(RecordingStudio::RootNotAllowed) do
      RecordingStudio.root_recording_for(folder)
    end
  end

  test "parentless child under an existing root is invalid" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Parentless Workspace")))
    folder = Folder.create!(name: unique_name("Parentless Folder"))
    recording = RecordingStudio::Recording.new(root_recording: root_recording, recordable: folder)

    assert_not recording.valid?
    assert_includes recording.errors[:parent_recording_id].join, "cannot be blank"
  end

  test "page cannot be recorded under another page" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Invalid Page Workspace")))
    page_recording = record_child(Page.new(title: unique_name("Parent Page")), root_recording, root_recording)

    error = assert_raises(RecordingStudio::InvalidParent) do
      record_child(Page.new(title: unique_name("Nested Page")), root_recording, page_recording)
    end
    assert_equal "Page cannot be recorded under Page", error.message
  end

  test "press kit can be recorded under the host workspace root" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Press Workspace")))

    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::PressKit",
      parent_recording: root_recording
    )

    recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    assert_equal root_recording, recording.parent_recording
    assert_equal root_recording, recording.root_recording
    assert_kind_of RecordingStudioPresskits::PressKit, recording.recordable
    assert_equal "recording_studio_press_kits", recording.recordable.class.table_name
  end

  test "many press kits can live under one workspace root" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Many Kits Workspace")))

    first = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    second = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Autumn recap")
    end

    assert_equal root_recording, first.parent_recording
    assert_equal root_recording, second.parent_recording
    assert_not_equal first.id, second.id
  end

  test "press kit title is required" do
    press_kit = RecordingStudioPresskits::PressKit.new

    assert_not press_kit.valid?
    assert_includes press_kit.errors[:title], "can't be blank"
  end

  test "press kit cannot be created as a root" do
    press_kit = RecordingStudioPresskits::PressKit.create!(
      title: unique_name("Root Rejected Press Kit")
    )

    assert_raises(RecordingStudio::RootNotAllowed) do
      RecordingStudio.root_recording_for(press_kit)
    end
  end

  test "press kit cannot be recorded under a folder" do
    workspace = Workspace.create!(name: unique_name("Press Parent Workspace"))
    root_recording = RecordingStudio.root_recording_for(workspace)
    folder_recording = record_child(Folder.new(name: unique_name("Press Folder")), root_recording, root_recording)

    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::PressKit",
      parent_recording: folder_recording
    )

    error = assert_raises(RecordingStudio::InvalidParent) do
      root_recording.record(
        RecordingStudioPresskits::PressKit,
        parent_recording: folder_recording
      ) do |press_kit|
        press_kit.title = unique_name("Nested Press Kit")
      end
    end

    assert_equal "RecordingStudioPresskits::PressKit cannot be recorded under Folder", error.message
  end

  test "fake block is allowed under a press kit and rejected under the workspace" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Block Workspace")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    assert RecordingStudio.parent_allowed?(child_type: "FakeBlock", parent_recording: kit_recording)
    refute RecordingStudio.parent_allowed?(child_type: "FakeBlock", parent_recording: root_recording)

    block_recording = kit_recording.record(FakeBlock, parent_recording: kit_recording) do |fake_block|
      fake_block.title = "Hero"
    end

    assert_equal kit_recording, block_recording.parent_recording
    assert_equal root_recording, block_recording.root_recording
    assert_kind_of FakeBlock, block_recording.recordable

    error = assert_raises(RecordingStudio::InvalidParent) do
      root_recording.record(FakeBlock) { |fake_block| fake_block.title = "Wrong parent" }
    end
    assert_equal "FakeBlock cannot be recorded under Workspace", error.message
  end

  test "press kit revise creates a new snapshot and log_event! appends history" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Revise Workspace")))
    recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Office hours")
    end
    original_id = recording.recordable_id

    recording.log_event!(action: "noted")
    root_recording.revise(recording) do |press_kit|
      press_kit.title = "Wednesday mornings."
    end

    recording.reload
    assert_not_equal original_id, recording.recordable_id
    assert_equal "Wednesday mornings.", recording.recordable.title
    assert_equal 1, recording.events.where(action: "noted").count
  end

  test "picker types include fake block and exclude types that do not allow press kit" do
    types = RecordingStudioPresskits.picker_types

    assert_includes types, "FakeBlock"
    refute_includes types, "Workspace"
    refute_includes types, "Folder"
    refute_includes types, "Page"
    refute_includes types, "RecordingStudioPresskits::PressKit"
    refute_includes types, "RecordingStudioPublishable::Publishable"
    refute_includes types, "RecordingStudioAttachable::Attachment"
  end

  test "accessible is enabled on workspace and admin root" do
    assert RecordingStudio.capability_enabled?(:accessible, for: "Workspace")
    assert RecordingStudio.capability_enabled?(:accessible, for: "AdminRoot")
    refute RecordingStudio.capability_enabled?(:accessible, for: "Folder")
    refute RecordingStudio.capability_enabled?(:accessible, for: "Page")
    refute RecordingStudio.capability_enabled?(:accessible, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:accessible, for: "FakeBlock")
  end

  test "orderable is enabled on press kit and dummy workspace" do
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:orderable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:orderable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Page")

    press_kit_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::PressKit").to_h
    refute press_kit_options.key?(:allows)

    workspace_options = RecordingStudio.capability_options(:orderable, for: "Workspace").to_h
    assert_equal ["RecordingStudioPresskits::PressKit"], Array(workspace_options[:allows]).map(&:to_s)
  end

  test "trashable is enabled on press kit and dummy fake block" do
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:trashable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Page")
  end

  test "publishable is enabled on press kit only" do
    assert RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:publishable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Page")

    options = RecordingStudio.capability_options(:publishable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal "recording_studio_presskits/public_press_kits", options[:public_controller]
    assert_equal :show, options[:public_action]
  end

  test "duplicatable is enabled on press kit only" do
    assert RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Page")

    options = RecordingStudio.capability_options(:duplicatable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal " (Copy)", options[:suffix]
    assert_equal [], options[:exclude_children]
  end

  private

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(4)}"
  end
end
