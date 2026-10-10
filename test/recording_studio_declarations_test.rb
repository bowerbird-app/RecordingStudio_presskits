# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class RecordingStudioDeclarationsTest < ActiveSupport::TestCase
  PICKER_TYPES_INCLUDED = %w[
    RecordingStudioPresskits::Text
    RecordingStudioPresskits::Images
    RecordingStudioPresskits::QuoteSection
    RecordingStudioPresskits::FactsSection
    RecordingStudioPresskits::CreditsSection
    RecordingStudioPresskits::VideoSection
  ].freeze

  PICKER_TYPES_EXCLUDED = %w[
    FakeBlock
    RecordingStudioPresskits::Quote
    RecordingStudioPresskits::Fact
    RecordingStudioPresskits::Credit
    RecordingStudioPresskits::CreditLine
    RecordingStudioVideo::Video
    Workspace
    Folder
    Page
    RecordingStudioPresskits::PressKit
    RecordingStudioPresskits::KitSection
    RecordingStudioPublishable::Publishable
    RecordingStudioAttachable::Attachment
    RecordingStudioCompany::Company
    RecordingStudio::Location::Location
  ].freeze
  test "dummy recordable declarations validate and expose parent/root introspection" do
    assert RecordingStudio.validate_recordable_declarations!
    assert_equal %w[AdminRoot Workspace], RecordingStudio.root_recordable_types.sort
    assert_equal %w[Workspace Folder], RecordingStudio.allowed_parent_types_for("Folder")
    assert_equal %w[Workspace Folder], RecordingStudio.allowed_parent_types_for(Page)
    assert_equal ["Workspace"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::PressKit")
    assert_equal ["RecordingStudioPresskits::PressKit"], RecordingStudio.allowed_parent_types_for("RecordingStudio::Location::Location")
    assert_includes RecordingStudio.allowed_parent_types_for("RecordingStudioCompany::Company"), "Workspace"
    assert_equal ["RecordingStudioPresskits::PressKit"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::KitSection")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("FakeBlock")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::Text")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::Images")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::QuoteSection")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::FactsSection")
    assert_equal ["RecordingStudioPresskits::FactsSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::Fact")
    assert_equal ["RecordingStudioPresskits::KitSection"], RecordingStudio.allowed_parent_types_for("RecordingStudioPresskits::VideoSection")
    refute RecordingStudio.root_allowed?("RecordingStudioPresskits::KitSection")
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

  test "press kit description is optional and capped at 280 characters" do
    press_kit = RecordingStudioPresskits::PressKit.new(title: unique_name("Named kit"))

    assert press_kit.valid?
    assert_nil press_kit.description

    press_kit.description = "  \n"
    assert press_kit.valid?
    assert_nil press_kit.description

    press_kit.description = "a" * RecordingStudioPresskits::PressKit::SHORT_DESCRIPTION_LIMIT
    assert press_kit.valid?

    press_kit.description = "a" * (RecordingStudioPresskits::PressKit::SHORT_DESCRIPTION_LIMIT + 1)
    assert_not press_kit.valid?
    assert press_kit.errors[:description].any?
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

  test "fake block is allowed under a kit section and rejected under the press kit" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Block Workspace")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    section = kit_recording.record(RecordingStudioPresskits::KitSection, parent_recording: kit_recording)

    assert RecordingStudio.parent_allowed?(child_type: "FakeBlock", parent_recording: section)
    refute RecordingStudio.parent_allowed?(child_type: "FakeBlock", parent_recording: kit_recording)
    refute RecordingStudio.parent_allowed?(child_type: "FakeBlock", parent_recording: root_recording)

    block_recording = section.record(FakeBlock, parent_recording: section) do |fake_block|
      fake_block.title = "Hero"
    end

    assert_equal section, block_recording.parent_recording
    assert_equal root_recording, block_recording.root_recording
    assert_kind_of FakeBlock, block_recording.recordable

    error = assert_raises(RecordingStudio::InvalidParent) do
      kit_recording.record(FakeBlock, parent_recording: kit_recording) do |fake_block|
        fake_block.title = "Wrong parent"
      end
    end
    assert_equal "FakeBlock cannot be recorded under RecordingStudioPresskits::PressKit", error.message
  end

  test "press kit revise creates a new snapshot and log_event! appends history" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Revise Workspace")))
    original_title = unique_name("Office hours")
    recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = original_title
    end
    original_id = recording.recordable_id

    recording.log_event!(action: "noted")
    root_recording.revise(recording) do |press_kit|
      press_kit.title = "Wednesday mornings."
      press_kit.description = "Doors at noon."
    end

    recording.reload
    assert_not_equal original_id, recording.recordable_id
    assert_equal "Wednesday mornings.", recording.recordable.title
    assert_equal "Doors at noon.", recording.recordable.description
    assert_equal 1, recording.events.where(action: "noted").count
    original = RecordingStudioPresskits::PressKit.find(original_id)
    assert_equal original_title, original.title
    assert_nil original.description
  end

  test "text is allowed under a kit section and stores only a body" do
    _root, kit = spring_kit
    section = record_section(kit, title: "Bio")
    text_type = "RecordingStudioPresskits::Text"

    assert RecordingStudio.parent_allowed?(child_type: text_type, parent_recording: section)
    refute RecordingStudio.parent_allowed?(child_type: text_type, parent_recording: kit)

    text_recording = section.record(RecordingStudioPresskits::Text, parent_recording: section) do |text|
      text.body = "Opening line\nMore"
    end

    assert_equal section, text_recording.parent_recording
    assert_kind_of RecordingStudioPresskits::Text, text_recording.recordable
    refute text_recording.recordable.respond_to?(:title)
    assert_equal "Bio", section.recordable.title
    assert_equal "Opening line\nMore", text_recording.recordable.body

    error = assert_raises(RecordingStudio::InvalidParent) do
      kit.record(RecordingStudioPresskits::Text, parent_recording: kit) { |text| text.body = "Wrong parent" }
    end
    assert_equal "#{text_type} cannot be recorded under RecordingStudioPresskits::PressKit", error.message
  end

  test "kit section stores a title and subtitle and blanks are nothing" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Section Heading")))
    kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end

    named = kit_recording.record(RecordingStudioPresskits::KitSection, parent_recording: kit_recording) do |section|
      section.title = "Bio"
      section.subtitle = "Doors at noon"
    end
    blank = kit_recording.record(RecordingStudioPresskits::KitSection, parent_recording: kit_recording) do |section|
      section.title = "   "
      section.subtitle = "   "
    end

    assert_equal "Bio", named.recordable.title
    assert_equal "Doors at noon", named.recordable.subtitle
    assert_nil blank.recordable.title
    assert_nil blank.recordable.subtitle
  end

  test "images is allowed under a kit section and uses library placements" do
    _root, kit_recording = spring_kit
    section = record_section(kit_recording)
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Images",
      parent_recording: section
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::Images",
      parent_recording: kit_recording
    )
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Images")
    assert RecordingStudio.capability_enabled?(:library_placement, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::VideoSection")
    assert RecordingStudio.capability_enabled?(:attachable, for: "RecordingStudioPresskits::Quote")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioAttachable::Attachment")

    images_recording = section.record(RecordingStudioPresskits::Images, parent_recording: section)
    assert_equal section, images_recording.parent_recording
    assert_kind_of RecordingStudioPresskits::Images, images_recording.recordable
    refute images_recording.recordable.respond_to?(:title=)
  end

  test "picker types skip dummy placeholders and types that do not allow press kit" do
    types = RecordingStudioPresskits.picker_types
    PICKER_TYPES_INCLUDED.each { |type| assert_includes types, type }
    PICKER_TYPES_EXCLUDED.each { |type| refute_includes types, type }

    assert_includes RecordingStudioPresskits.section_types, "FakeBlock"
    assert_includes RecordingStudioPresskits.section_types, "RecordingStudioPresskits::Text"
    refute RecordingStudioPresskits.section?("RecordingStudioPublishable::Publishable")
    refute RecordingStudioPresskits.section?("RecordingStudioPresskits::Text")
    assert RecordingStudioPresskits.section?("RecordingStudioPresskits::KitSection")
  end

  test "a kit section stays a section when its content type leaves the registry" do
    root_recording = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Section Registry")))
    kit = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      title: "Hello"
    )
    aside = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      title: "Aside"
    )
    publishable = publish_kit(kit, root_recording)

    assert_equal [text.id, aside.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert RecordingStudioPresskits.section?(text)
    refute RecordingStudioPresskits.section?(RecordingStudioPresskits::KitQuery.section_content(aside))
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), publishable.id

    RecordingStudioPresskits.configuration.section_types.delete("FakeBlock")
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), aside.id
    assert RecordingStudioPresskits.section?(aside)
  ensure
    RecordingStudioPresskits.register_section("FakeBlock", component: "FakeBlock::Component")
  end

  test "shipped sections name a menu icon" do
    assert_equal "document-text", RecordingStudioPresskits::Text.section_menu_icon
    assert_equal "photo", RecordingStudioPresskits::Images.section_menu_icon
    assert_equal "chat-bubble-bottom-center-text", RecordingStudioPresskits::QuoteSection.section_menu_icon
    assert_equal "calculator", RecordingStudioPresskits::FactsSection.section_menu_icon
    assert_equal "user-group", RecordingStudioPresskits::CreditsSection.section_menu_icon
    assert_equal "video-camera", RecordingStudioPresskits::VideoSection.section_menu_icon
    assert_nil FakeBlock.try(:section_menu_icon)
  end

  test "accessible is enabled on workspace and admin root" do
    assert RecordingStudio.capability_enabled?(:accessible, for: "Workspace")
    assert RecordingStudio.capability_enabled?(:companies, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:companies, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:location, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:location, for: "Workspace")
    assert RecordingStudio.capability_enabled?(:image_library, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:image_library, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:library_placement, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:library_placement, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:library_placement, for: "Workspace")
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
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::KitSection")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Text")
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Quote")
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::QuoteSection")
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::FactsSection")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Fact")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::VideoSection")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:orderable, for: "Page")

    press_kit_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal ["RecordingStudioPresskits::KitSection", "RecordingStudioAttachable::Placement"],
                 Array(press_kit_options[:allows]).map(&:to_s)

    quote_section_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::QuoteSection").to_h
    assert_equal ["RecordingStudioPresskits::Quote"], Array(quote_section_options[:allows]).map(&:to_s)

    facts_section_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::FactsSection").to_h
    assert_equal ["RecordingStudioPresskits::Fact"], Array(facts_section_options[:allows]).map(&:to_s)

    images_options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::Images").to_h
    assert_equal ["RecordingStudioAttachable::Placement"], Array(images_options[:allows]).map(&:to_s)

    workspace_options = RecordingStudio.capability_options(:orderable, for: "Workspace").to_h
    assert_equal ["RecordingStudioPresskits::PressKit"], Array(workspace_options[:allows]).map(&:to_s)
  end

  test "trashable is enabled on press kit and dummy fake block" do
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::PressKit")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::KitSection")
    assert RecordingStudio.capability_enabled?(:trashable, for: "FakeBlock")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Text")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Images")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::QuoteSection")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Quote")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::FactsSection")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Fact")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::VideoSection")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioVideo::Video")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudio::Location::Location")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:trashable, for: "Page")
  end

  test "publishable is enabled on press kit only" do
    assert RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:publishable, for: "FakeBlock")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::KitSection")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Quote")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::FactsSection")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Fact")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::VideoSection")
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
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::KitSection")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Quote")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::FactsSection")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::Fact")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::VideoSection")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Workspace")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "Page")

    options = RecordingStudio.capability_options(:duplicatable, for: "RecordingStudioPresskits::PressKit").to_h
    assert_equal " (Copy)", options[:suffix]
    assert_equal [], options[:exclude_children]
  end

  test "videos capability is enabled on the video section only" do
    assert RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::VideoSection")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::KitSection")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::PressKit")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::Text")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::Images")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::QuoteSection")
    refute RecordingStudio.capability_enabled?(:videos, for: "RecordingStudioPresskits::Quote")

    assert_equal "Video", RecordingStudio.recordable_type_label("RecordingStudioPresskits::VideoSection")
    refute RecordingStudio.root_allowed?("RecordingStudioPresskits::VideoSection")
  end

  test "video section sits under a kit section and videos sit under the video section" do
    root, kit = spring_kit
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::VideoSection"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)

    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::VideoSection", parent_recording: section
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::VideoSection", parent_recording: kit
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::VideoSection", parent_recording: root
    )
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioVideo::Video", parent_recording: content
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioVideo::Video", parent_recording: section
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioVideo::Video", parent_recording: kit
    )
  end

  test "quote section sits under a kit section and quotes sit under the quote section" do
    root, kit, section = quote_tree
    kit_section = section.parent_recording

    assert_kind_of RecordingStudioPresskits::KitSection, kit_section.recordable
    assert_equal kit, kit_section.parent_recording
    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::KitSection", parent_recording: kit)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::QuoteSection", parent_recording: kit)
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::QuoteSection",
      parent_recording: kit_section
    )
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::QuoteSection", parent_recording: root)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Quote", parent_recording: kit_section)
    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Quote", parent_recording: section)
    refute section.recordable.respond_to?(:title=)
    refute section.recordable.respond_to?(:body=)
    assert_nil kit_section.recordable.title
  end

  test "facts section sits under a kit section and facts sit under the facts section" do
    root, kit = spring_kit
    kit_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::FactsSection"
    )
    section = RecordingStudioPresskits::KitQuery.section_content(kit_section)

    assert_kind_of RecordingStudioPresskits::KitSection, kit_section.recordable
    assert_equal kit, kit_section.parent_recording
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::FactsSection",
      parent_recording: kit_section
    )
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::FactsSection", parent_recording: kit)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::FactsSection", parent_recording: root)
    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Fact", parent_recording: section)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Fact", parent_recording: kit_section)
    refute section.recordable.respond_to?(:title=)
    assert_equal "list", section.recordable.display_style
    assert_equal 3, section.recordable.columns
    assert_nil kit_section.recordable.title
    assert_equal "Facts & Figures", RecordingStudioPresskits.section_heading(kit_section)
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

  test "a credit lives on the workspace and a line lives under the credits section" do
    root, kit = spring_kit
    credit = RecordingStudioPresskits::Credits.create!(
      root_recording: root,
      name: "Tom Ross",
      usual_role: "Photography",
      url: "https://example.com/tom"
    )
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::CreditsSection",
      title: "Project credits"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)

    assert_equal root, credit.parent_recording
    assert_equal "Credits", content.type_label
    assert_credit_placement(root, kit, section, content)
    assert_credit_capabilities
  end

  private

  def assert_credit_placement(root, kit, section, content)
    assert RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Credit", parent_recording: root)
    refute RecordingStudio.parent_allowed?(child_type: "RecordingStudioPresskits::Credit", parent_recording: kit)
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::CreditsSection",
      parent_recording: section
    )
    assert RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::CreditLine",
      parent_recording: content
    )
    refute RecordingStudio.parent_allowed?(
      child_type: "RecordingStudioPresskits::CreditLine",
      parent_recording: section
    )
  end

  def assert_credit_capabilities
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::Credit")
    assert RecordingStudio.capability_enabled?(:trashable, for: "RecordingStudioPresskits::CreditLine")
    assert RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::CreditsSection")
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::Credit")
    refute RecordingStudio.capability_enabled?(:publishable, for: "RecordingStudioPresskits::Credit")
    refute RecordingStudio.capability_enabled?(:duplicatable, for: "RecordingStudioPresskits::CreditLine")

    options = RecordingStudio.capability_options(:orderable, for: "RecordingStudioPresskits::CreditsSection").to_h
    assert_equal ["RecordingStudioPresskits::CreditLine"], Array(options[:allows]).map(&:to_s)
  end

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end

  def spring_kit
    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Workspace")))
    kit = root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    [root, kit]
  end

  def record_section(kit, title: nil)
    kit.record(RecordingStudioPresskits::KitSection, parent_recording: kit) do |section|
      section.title = title
    end
  end

  def publish_kit(kit, root)
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: quote_owner(root),
      attributes: {
        slug: "registry-#{SecureRandom.hex(4)}",
        status: "published",
        meta_robots: "index,follow"
      }
    ).value
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(4)}"
  end

  def quote_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Quote Workspace")))
    kit = root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = unique_name("Spring launch")
    end
    kit_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::QuoteSection"
    )
    [root, kit, RecordingStudioPresskits::KitQuery.section_content(kit_section)]
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
