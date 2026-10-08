# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class VideoSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ZOO_URL = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
  RICK_URL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  VIMEO_URL = "https://vimeo.com/76979871"

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "video-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Video Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "create section stores the heading and no video row" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::VideoSection.count }, 1 do
        assert_no_difference -> { RecordingStudioVideo::Video.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::VideoSection",
            actor: @user,
            title: "Trailer",
            subtitle: "Two minutes"
          )
        end
      end
    end

    content = RecordingStudioPresskits::KitQuery.section_content(@section)
    assert_equal "Trailer", @section.recordable.title
    assert_equal "Two minutes", @section.recordable.subtitle
    assert_equal @section, content.parent_recording
    assert_kind_of RecordingStudioPresskits::VideoSection, content.recordable
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "Trailer",
        subtitle: "Two minutes",
        content_type: "RecordingStudioPresskits::VideoSection",
        content_id: content.id,
        videos: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "videos hang off the video section in created order and revise keeps the old snapshot" do
    kit = record_kit("Spring launch")
    section = add_video_section(kit)
    content = section_content(section)
    first = record_video(content, url: ZOO_URL, title: "Me at the zoo", description: "First")
    second = record_video(content, url: RICK_URL, title: "Second reel", description: "Later")
    snapshot_id = first.recordable_id

    assert_equal content, RecordingStudioPresskits::KitQuery.section_content(section)
    assert_equal [first.id, second.id], content.videos.map(&:id)
    assert_empty section.child_recordings.select { |child| child.recordable.is_a?(RecordingStudioVideo::Video) }

    assert_difference -> { RecordingStudioVideo::Video.count }, 1 do
      @root.revise(first, actor: @user) do |video|
        video.url = RICK_URL
        video.title = "Renamed"
        video.description = "Changed"
      end
    end

    assert_equal ZOO_URL, RecordingStudioVideo::Video.find(snapshot_id).url
    assert_equal "First", RecordingStudioVideo::Video.find(snapshot_id).description
    assert_equal RICK_URL, first.reload.recordable.url
    assert_equal "Changed", first.recordable.description
    refute_equal snapshot_id, first.recordable_id
  end

  test "a vimeo url fails validation" do
    kit = record_kit("Spring launch")
    content = section_content(add_video_section(kit))

    error = nil
    assert_no_difference -> { RecordingStudioVideo::Video.count } do
      error = assert_raises(ActiveRecord::RecordInvalid) do
        record_video(content, url: VIMEO_URL, title: "Nope", description: "No")
      end
    end

    assert_instance_of RecordingStudioVideo::Video, error.record
    assert_includes error.record.errors[:url], "That URL is not from a supported provider."
  end

  test "kit section order leaves videos in place and videos are not orderable" do
    kit = record_kit("Spring launch")
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    videos = add_video_section(kit, title: "Trailer")
    content = section_content(videos)
    child = record_video(content, url: ZOO_URL, title: "Me at the zoo", description: "First")

    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [videos.id, text.id],
      actor: @user
    )

    assert_equal [videos.id, text.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), child.id
    assert content.respond_to?(:recording_studio_orderable_children)
    assert_raises(RecordingStudio::CapabilityDisabled) { content.recording_studio_orderable_children }
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::VideoSection")

    names = RecordingStudioPresskits::Engine.routes.named_routes.names.map(&:to_s)
    refute names.any? { |name| name.include?("video_order") }
    assert_includes names, "press_kit_section_quote_order"
  end

  test "deleting one video trashes that recording only" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_video_section(kit)
    content = section_content(section)
    first = record_video(content, url: ZOO_URL, title: "Me at the zoo", description: "First")
    second = record_video(content, url: RICK_URL, title: "Second reel", description: "Later")
    video_count = RecordingStudioVideo::Video.count

    delete recording_studio_presskits.press_kit_section_video_path(kit, section, first)

    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert first.reload.trashed_at.present?
    assert_nil second.reload.trashed_at
    assert_nil content.reload.trashed_at
    assert_nil section.reload.trashed_at
    assert_equal video_count, RecordingStudioVideo::Video.count
    assert_equal [second.id], RecordingStudioPresskits::VideoSection.active_videos(content).map(&:id)
  end

  test "deleting the section trashes that subtree and leaves other videos" do
    kit = record_kit("Spring launch")
    other = record_kit("Autumn recap")
    sign_in @user
    switch_to_root(@root)
    section = add_video_section(kit, title: "Trailer")
    content = section_content(section)
    first = record_video(content, url: ZOO_URL, title: "Me at the zoo", description: "First")
    second = record_video(content, url: RICK_URL, title: "Second reel", description: "Later")
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Notes"
    )
    sibling = add_video_section(kit, title: "Extra")
    sibling_video = record_video(section_content(sibling), url: ZOO_URL, title: "Kept", description: "Here")
    outsider = add_video_section(other, title: "Elsewhere")
    outside_video = record_video(section_content(outsider), url: RICK_URL, title: "Other kit", description: "There")
    sibling_video_id = sibling_video.id
    outside_video_id = outside_video.id
    recording_count = RecordingStudio::Recording.count
    video_count = RecordingStudioVideo::Video.count

    delete recording_studio_presskits.press_kit_section_path(kit, section)

    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert_equal true, section.trash_root
    assert content.reload.trashed_at.present?
    assert_equal false, content.trash_root
    [first, second].each do |video|
      assert video.reload.trashed_at.present?
      assert_equal false, video.trash_root
    end
    assert_nil kit.reload.trashed_at
    assert_nil text.reload.trashed_at
    assert_nil RecordingStudioPresskits::KitQuery.section_content(text).trashed_at
    assert_nil sibling.reload.trashed_at
    assert_nil sibling_video.reload.trashed_at
    assert_equal sibling_video_id, sibling_video.id
    assert_nil outside_video.reload.trashed_at
    assert_equal outside_video_id, outside_video.id
    assert_nil outsider.reload.trashed_at
    assert_equal recording_count, RecordingStudio::Recording.count
    assert_equal video_count, RecordingStudioVideo::Video.count
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), section.id
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), text.id
    assert_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), sibling.id
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_video_section(kit, title: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::VideoSection",
      actor: @user,
      title: title
    )
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def record_video(content, url:, title:, description:)
    content.record(RecordingStudioVideo::Video, parent_recording: content, actor: @user) do |video|
      video.url = url
      video.title = title
      video.description = description
    end
  end

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
