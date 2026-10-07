# frozen_string_literal: true

require "test_helper"

class KitSectionTreeTest < ActiveSupport::TestCase
  test "create_section stores headings on the kit section and body on the text child" do
    root, kit = kit_tree

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::Text.count }, 1 do
        @section = RecordingStudioPresskits.create_section!(
          press_kit_recording: kit,
          content_type: "RecordingStudioPresskits::Text",
          actor: owner_for(root),
          title: "Launch notes",
          subtitle: "Doors at noon"
        )
      end
    end

    content = RecordingStudioPresskits::KitQuery.section_content(@section)
    assert_equal kit.id, @section.parent_recording_id
    assert_equal "Launch notes", @section.recordable.title
    assert_equal "Doors at noon", @section.recordable.subtitle
    assert_equal @section.id, content.parent_recording_id
    assert_equal RecordingStudioPresskits::Text.opening_body, content.recordable.body
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "Launch notes",
        subtitle: "Doors at noon",
        content_type: "RecordingStudioPresskits::Text",
        content_id: content.id
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "a failed content create leaves no kit section" do
    _root, kit = kit_tree
    name = "RecordingStudioPresskits::Text"
    previous = RecordingStudioPresskits.configuration.section_prepares[name]
    RecordingStudioPresskits.configuration.section_prepares[name] = lambda { |recordable, **|
      recordable.body = ""
    }

    assert_no_difference -> { RecordingStudio::Recording.where(recordable_type: RecordingStudioPresskits::KitSection.name).count } do
      assert_no_difference -> { RecordingStudioPresskits::Text.count } do
        assert_raises(ActiveRecord::RecordInvalid) do
          RecordingStudioPresskits.create_section!(press_kit_recording: kit, content_type: name)
        end
      end
    end
    assert_empty RecordingStudioPresskits::KitQuery.sections_for(kit)
  ensure
    RecordingStudioPresskits.configuration.section_prepares[name] = previous if name
  end

  test "legacy sections become kit sections in order with headings and nested quotes" do
    root, kit = kit_tree
    owner_for(root)
    add_heading_columns
    images = legacy_content(kit, "RecordingStudioPresskits::Images", position: 0)
    text = legacy_content(kit, "RecordingStudioPresskits::Text", position: 2)
    quotes = legacy_content(kit, "RecordingStudioPresskits::QuoteSection", position: 1)
    quote = quotes.record(RecordingStudioPresskits::Quote, parent_recording: quotes) do |recordable|
      recordable.body = "A line worth printing"
      recordable.name = "Ada"
    end
    RecordingStudioPresskits::Images.reset_column_information
    RecordingStudioPresskits::Text.reset_column_information
    RecordingStudioPresskits::Images.where(id: images.recordable_id).update_all(title: "Press photos", subtitle: "Doors at noon")
    RecordingStudioPresskits::Text.where(id: text.recordable_id).update_all(title: "Bio")
    text_id = text.id
    quote_id = quote.id

    RecordingStudioPresskits::LegacySectionTree.migrate!

    sections = RecordingStudioPresskits::KitQuery.sections_for(kit).to_a
    assert_equal(
      ["RecordingStudioPresskits::Images", "RecordingStudioPresskits::QuoteSection", "RecordingStudioPresskits::Text"],
      sections.map { |section| RecordingStudioPresskits::KitQuery.section_content(section).recordable_type }
    )
    assert_equal ["Press photos", "Quotes", "Bio"], sections.map { |section| section.recordable.title }
    assert_equal ["Doors at noon", nil, nil], sections.map { |section| section.recordable.subtitle }
    migrated_text = RecordingStudioPresskits::KitQuery.section_content(sections.last)
    assert_equal text_id, migrated_text.id
    assert_includes migrated_text.recordable.body, "Launch notes"
    migrated_quotes = RecordingStudioPresskits::KitQuery.section_content(sections[1])
    assert_equal [quote_id], migrated_quotes.child_recordings.map(&:id)
    assert_equal quotes.id, migrated_quotes.id

    RecordingStudioPresskits::LegacySectionTree.migrate!
    assert_equal sections.map(&:id), RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
  end

  test "a trashed legacy section stays trashed under the new kit section" do
    root, kit = kit_tree
    user = owner_for(root)
    text = legacy_content(kit, "RecordingStudioPresskits::Text", position: 0, trash_actor: user)

    RecordingStudioPresskits::LegacySectionTree.migrate!

    text.reload
    section = text.parent_recording
    assert_equal "RecordingStudioPresskits::KitSection", section.recordable_type
    assert section.trashed_at.present?
    assert_equal true, section.trash_root
    assert text.trashed_at.present?
    assert_equal false, text.trash_root
    assert_empty RecordingStudioPresskits::KitQuery.sections_for(kit)
  end

  test "duplicating a press kit copies the quote tree" do
    root, kit = kit_tree
    user = owner_for(root)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::QuoteSection",
      title: "Praise",
      actor: user
    )
    quotes = RecordingStudioPresskits::KitQuery.section_content(section)
    first = quotes.record(RecordingStudioPresskits::Quote, parent_recording: quotes) do |quote|
      quote.body = "First line"
      quote.name = "Ada"
    end
    quotes.record(RecordingStudioPresskits::Quote, parent_recording: quotes) do |quote|
      quote.body = "Second line"
      quote.name = "Grace"
    end

    duplicate = kit.duplicate_in_place!(actor: user)
    copied_section = duplicate.child_recordings.find { |child| child.recordable.is_a?(RecordingStudioPresskits::KitSection) }
    copied_quotes = RecordingStudioPresskits::KitQuery.section_content(copied_section)

    assert_equal "Praise (Copy)", copied_section.recordable.title
    assert_equal "RecordingStudioPresskits::QuoteSection", copied_quotes.recordable_type
    assert_equal ["First line", "Second line"], copied_quotes.child_recordings.map { |child| child.recordable.body }
    refute_includes copied_quotes.child_recordings.map(&:id), first.id
  end

  def after_teardown
    super
    ActiveRecord::Base.connection.clear_cache!
    RecordingStudioPresskits::Text.reset_column_information
    RecordingStudioPresskits::Images.reset_column_information
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Kit #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "section-#{SecureRandom.hex(4)}@example.com",
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

  def add_heading_columns
    connection = ActiveRecord::Base.connection
    connection.add_column :recording_studio_texts, :title, :text unless connection.column_exists?(:recording_studio_texts, :title)
    return if connection.column_exists?(:recording_studio_images, :title)

    connection.add_column :recording_studio_images, :title, :text
    connection.add_column :recording_studio_images, :subtitle, :text
  end

  def legacy_content(kit, type_name, position:, trash_actor: nil)
    section = RecordingStudioPresskits.create_section!(press_kit_recording: kit, content_type: type_name)
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    content.recording_studio_trashable_trash!(actor: trash_actor) if trash_actor
    content.update_columns(parent_recording_id: kit.id, recording_studio_orderable_position: position)
    RecordingStudio::Event.where(recording_id: section.id).delete_all
    RecordingStudio::Recording.where(id: section.id).delete_all
    content.reload
  end
end
