# frozen_string_literal: true

require "test_helper"

class SectionAnchorTest < ActiveSupport::TestCase
  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "section-anchor-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    workspace = Workspace.create!(name: "Anchor Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
    @kit = @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "a blank recording has no anchor" do
    assert_nil RecordingStudioPresskits.section_anchor_id(nil)
  end

  test "the anchor is the parameterized heading" do
    section = add_text("About the launch")

    assert_equal "about-the-launch", RecordingStudioPresskits.section_anchor_id(section)
  end

  test "a blank title uses the content type label" do
    section = add_text(nil)

    assert_equal "text", RecordingStudioPresskits.section_anchor_id(section)
  end

  test "a heading that parameterizes to nothing uses the section id" do
    section = add_text("???")

    assert_equal "section-#{section.id}", RecordingStudioPresskits.section_anchor_id(section)
  end

  test "duplicate headings keep the first id and suffix the rest in kit order" do
    first = add_text("Photos")
    second = add_text("Photos")
    third = add_text("Photos")

    assert_equal "photos", RecordingStudioPresskits.section_anchor_id(first)
    assert_equal "photos-2", RecordingStudioPresskits.section_anchor_id(second)
    assert_equal "photos-3", RecordingStudioPresskits.section_anchor_id(third)
  end

  test "a later suffix skips an id another heading already uses" do
    photos = add_text("Photos")
    numbered = add_text("Photos 2")
    again = add_text("Photos")

    assert_equal "photos", RecordingStudioPresskits.section_anchor_id(photos)
    assert_equal "photos-2", RecordingStudioPresskits.section_anchor_id(numbered)
    assert_equal "photos-3", RecordingStudioPresskits.section_anchor_id(again)
    assert_equal(
      ["photos", "photos-2", "photos-3"],
      [photos, numbered, again].map { |section| RecordingStudioPresskits.section_anchor_id(section) }.uniq
    )
  end

  test "reordering the kit changes which section keeps the base id" do
    first = add_text("Photos")
    second = add_text("Photos")

    @kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )

    assert_equal "photos", RecordingStudioPresskits.section_anchor_id(second)
    assert_equal "photos-2", RecordingStudioPresskits.section_anchor_id(first)
  end

  test "two menus with the default title get contents and contents-2" do
    first = add_menu
    second = add_menu

    assert_equal "Contents", first.recordable.title
    assert_equal "contents", RecordingStudioPresskits.section_anchor_id(first)
    assert_equal "contents-2", RecordingStudioPresskits.section_anchor_id(second)
  end

  private

  def add_text(title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: title
    )
  end

  def add_menu
    RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::MenuSection",
      actor: @user
    )
  end
end
