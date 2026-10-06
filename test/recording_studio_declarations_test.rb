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

  test "text is allowed under a press kit and rejected under the workspace" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Text Workspace")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Text",
      parent_recording: kit_recording
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Text",
      parent_recording: root_recording
    )

    text_recording = kit_recording.record(RecordingStudioPresskits::Text, parent_recording: kit_recording) do |text|
      text.body = "Opening line\nMore"
    end

    assert_equal kit_recording, text_recording.parent_recording
    assert_kind_of RecordingStudioPresskits::Text, text_recording.recordable
    assert_nil text_recording.recordable.title

    error = assert_raises(RecordingStudio::InvalidParent) do
      root_recording.record(RecordingStudioPresskits::Text) { |text| text.body = "Wrong parent" }
    end
    assert_equal "RecordingStudioPresskits::Text cannot be recorded under Workspace", error.message
  end

  test "text title is stored and a blank title is nothing" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Text Title Workspace")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    named = kit_recording.record(RecordingStudioPresskits::Text, parent_recording: kit_recording) do |text|
      text.title = "Bio"
      text.body = "Opening line\nMore"
    end
    blank = kit_recording.record(RecordingStudioPresskits::Text, parent_recording: kit_recording) do |text|
      text.title = "   "
      text.body = "Still here"
    end

    assert_equal "Bio", named.recordable.title
    refute_equal "Opening line", named.recordable.title
    assert_nil blank.recordable.title
  end

  test "images is allowed under a press kit and uses attachable" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Images Workspace")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Images",
      parent_recording: kit_recording
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Images",
      parent_recording: root_recording
    )
    assert RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::QuoteSection")
    assert RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Quote")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioAttachable::Attachment")

    options = RecordingStudio.capability_options(:attachable, for: "RecordingStudioPresskits::Images").to_h
    assert_equal ["image/*"], options[:allowed_content_types]
    assert_equal [:image], options[:enabled_attachment_kinds]
    assert_equal :edit, options[:auth_roles][:remove]

    images_recording = kit_recording.record(RecordingStudioPresskits::Images, parent_recording: kit_recording)
    assert_equal kit_recording, images_recording.parent_recording
    assert_kind_of RecordingStudioPresskits::Images, images_recording.recordable
  end

  test "picker types skip dummy placeholders and types that do not allow press kit" do
    types = RecordingStudioPresskits.picker_types

    refute_includes types, "FakeBlock"
    assert_includes types, "RecordingStudioPresskits::Text"
    assert_includes types, "RecordingStudioPresskits::Images"
    assert_includes types, "RecordingStudioPresskits::QuoteSection"
    refute_includes types, "RecordingStudioPresskits::Quote"
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
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Quote")
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Page")

    press_kit_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::PressKit").to_h
    refute press_kit_options.key?(:allows)

    quote_section_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::QuoteSection").to_h
    assert_equal ["RecordingStudioPresskits::Quote"], Array(quote_section_options[:allows]).map(&:to_s)

    workspace_options = RecordingStudio.capability_options(:orderable, for: "Workspace").to_h
    assert_equal ["RecordingStudioPresskits::PressKit"], Array(workspace_options[:allows]).map(&:to_s)
  end

  test "trashable is enabled on press kit and dummy fake block" do
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:trashable, for: "FakeBlock")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Text")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Images")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::QuoteSection")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Quote")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Page")
  end

  test "publishable is enabled on press kit only" do
    assert RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:publishable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Quote")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:publishable, for: "Page")

    options = RecordingStudio.capability_options(:publishable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal "recording_studio_presskits/public_press_kits", options[:public_controller]
    assert_equal :show, options[:public_action]
    assert_equal "recording_studio_presskits/blank", options[:public_layout]
  end

  test "duplicatable is enabled on press kit only" do
    assert RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Quote")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Page")

    options = RecordingStudio.capability_options(:duplicatable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal " (Copy)", options[:suffix]
    assert_equal [], options[:exclude_children]
  end

  test "quote section parent is press kit and quote parent is the section" do
    root, kit, section = quote_tree

    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::QuoteSection", parent_recording: kit)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::QuoteSection", parent_recording: root)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Quote", parent_recording: kit)
    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Quote", parent_recording: section)
    assert_equal "Quotes", section.recordable.title
    refute section.recordable.respond_to?(:title=)
    refute section.recordable.respond_to?(:body=)
  end

  test "quote attachable allows one image" do
    options = RecordingStudio.capability_options(:attachable, for: "RecordingStudioPresskits::Quote").to_h

    assert_equal ["image/*"], options[:allowed_content_types]
    assert_equal [:image], options[:enabled_attachment_kinds]
    assert_equal :edit, options[:auth_roles][:remove]
  end

  test "recording a quote stores the words on that recordable" do
    _root, _kit, section = quote_tree
    first = record_quote(section, body: "First line", name: "Ada", role: "Editor", organisation: "Press")
    second = record_quote(section, body: "Second line", name: "Grace", role: nil, organisation: nil)

    assert_kind_of RecordingStudio::Recording, first
    assert_equal section.id, first.parent_recording_id
    assert_equal "First line", first.recordable.body
    assert_equal "Ada", first.recordable.name
    assert_equal "Editor", first.recordable.role
    assert_equal "Press", first.recordable.organisation
    assert_equal "Ada", first.recordable.title
    assert_nil second.recordable.role
    assert_nil second.recordable.organisation
  end

  test "revise changes one quote and leaves the other" do
    root, _kit, section = quote_tree
    first = record_quote(section, body: "First line", name: "Ada", role: "Editor", organisation: "Press")
    second = record_quote(section, body: "Second line", name: "Grace", role: nil, organisation: nil)

    root.revise(first) { |quote| quote.body = "Revised line" }

    assert_equal "Revised line", first.reload.recordable.body
    assert_equal "Second line", second.reload.recordable.body
  end

  test "moving a quote changes the section order" do
    root, _kit, section = quote_tree
    user = quote_owner(root)
    first = record_quote(section, body: "First line", name: "Ada", role: nil, organisation: nil)
    second = record_quote(section, body: "Second line", name: "Grace", role: nil, organisation: nil)

    section.recording_studio_orderable_move!(second, to_index: 0, actor: user)

    assert_equal [second.id, first.id], section.recording_studio_orderable_children.map(&:id)
  end

  test "trashing a quote leaves the section and the other quote" do
    root, _kit, section = quote_tree
    user = quote_owner(root)
    first = record_quote(section, body: "First line", name: "Ada", role: nil, organisation: nil)
    second = record_quote(section, body: "Second line", name: "Grace", role: nil, organisation: nil)

    first.recording_studio_trashable_trash!(actor: user)

    assert first.reload.trashed_at.present?
    assert_nil section.reload.trashed_at
    assert_nil second.reload.trashed_at
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

  def quote_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Quote Workspace")))
    kit = root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    section = kit.record(RecordingStudioPresskits::QuoteSection, parent_recording: kit)
    [root, kit, section]
  end

  def quote_owner(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "quote-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = user
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root_recording, actor: user)
    raise result.error if result.failure?

    user
  ensure
    Current.actor = previous
  end

  def record_quote(section, body:, name:, role:, organisation:)
    section.record(RecordingStudioPresskits::Quote, parent_recording: section) do |quote|
      quote.body = body
      quote.name = name
      quote.role = role
      quote.organisation = organisation
    end
  end
end
