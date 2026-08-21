# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitPublishableTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "publish-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Publish Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "press kit is publishable and fake block is not" do
    assert RecordingStudio.capability_enabled?(:publishable, for: RecordingStudioPresskits::PressKit)
    refute RecordingStudio.capability_enabled?(:publishable, for: FakeBlock)
    refute_includes RecordingStudioPresskits.picker_types, "RecordingStudioPublishable::Publishable"
  end

  test "publish and unpublish go through publishable update" do
    kit = record_kit("Spring launch")

    publish_kit!(kit, slug: "spring-launch", status: "published")
    kit.reload

    assert kit.currently_published?
    assert kit.recordable.published?
    assert kit.recordable.indexable?
    assert_equal "/published/#{kit.publishable_child_recording.id}/spring-launch", kit.publishable_public_path

    publish_kit!(kit, slug: "spring-launch", status: "draft")
    kit.reload

    refute kit.currently_published?
    refute kit.recordable.published?
    refute kit.recordable.indexable?
    assert_nil kit.publishable_public_path
  end

  test "indexable lists published kits and skips unpublished ones" do
    live = record_kit("Spring launch")
    draft = record_kit("Autumn recap")
    publish_kit!(live, slug: "spring-launch", status: "published")
    publish_kit!(draft, slug: "autumn-recap", status: "draft")

    assert_includes RecordingStudioPresskits::PressKit.indexable.map(&:title), live.recordable.title
    refute_includes RecordingStudioPresskits::PressKit.indexable.map(&:title), draft.recordable.title
    assert_includes RecordingStudioPresskits::KitQuery.published_kits.map(&:id), live.id
    assert_includes RecordingStudioPresskits::KitQuery.unpublished_kits.map(&:id), draft.id
  end

  test "logged-out visitors can read a published kit on the public path" do
    kit = record_kit("Spring launch")
    record_block(kit, "Hero")
    record_block(kit, "Quotes")
    publish_kit!(kit, slug: "spring-launch", status: "published")

    get kit.publishable_public_path
    assert_response :success
    assert_select "html[data-theme='rounded']", count: 1
    assert_includes response.body, "recording_studio-publishable-layout"
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Hero"
    assert_includes response.body, "Quotes"
    refute_includes response.body, "Dummy host"
    refute_includes response.body, "data-recording-studio-default-layout"
  end

  test "logged-out visitors cannot read an unpublished kit" do
    kit = record_kit("Autumn recap")
    publish_kit!(kit, slug: "autumn-recap", status: "draft")

    get "/published/#{kit.publishable_child_recording.id}/autumn-recap"
    assert_response :not_found
  end

  test "owner can preview an unpublished kit on the default layout" do
    kit = record_kit("Autumn recap")
    record_block(kit, "Notes")
    publish_kit!(kit, slug: "autumn-recap", status: "draft")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_page_nav_close
    assert_includes response.body, "Autumn recap"
    assert_includes response.body, "This is just for you"
    assert_includes response.body, "Notes"
    refute_includes response.body, "Dummy host"
  end

  test "logged-out visitors cannot preview an unpublished kit" do
    kit = record_kit("Autumn recap")
    publish_kit!(kit, slug: "autumn-recap", status: "draft")

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_redirected_to new_user_session_path
  end

  test "outsider cannot preview a kit they cannot view" do
    kit = record_kit("Autumn recap")
    publish_kit!(kit, slug: "autumn-recap", status: "draft")
    outsider = User.create!(
      email: "preview-denied-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    switch_to_root(@root)

    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :forbidden
  end

  test "publishable engine is mounted and live children skip the publishable child" do
    kit = record_kit("Spring launch")
    record_block(kit, "Hero")
    publish_kit!(kit, slug: "spring-launch", status: "published")

    engine_routes = RecordingStudioPublishable::Engine.routes.routes.map { |route| route.path.spec.to_s }
    assert(engine_routes.any? { |path| path.include?("/published/:uuid/:slug") })

    children = RecordingStudioPresskits::KitQuery.live_children(kit)
    assert_equal ["Hero"], children.map { |child| child.recordable.title }
    refute_includes children.map(&:recordable_type), "RecordingStudioPublishable::Publishable"
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

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_block(kit, title)
    kit.record(FakeBlock, parent_recording: kit) { |fake_block| fake_block.title = title }
  end

  def publish_kit!(kit, slug:, status:)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: slug, status: status, meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end
end
