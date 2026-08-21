# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitUiTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "ui-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "UI Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "root redirects to the mounted press kit index" do
    sign_in @user
    switch_to_root(@root)

    get "/"
    assert_redirected_to "/recording_studio_presskits"
    follow_redirect!

    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Press kits"
    refute_includes response.body, "Dummy host"
  end

  test "index cards and table show the same kits" do
    record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Cards"
    assert_includes response.body, "Table"
    assert_includes response.body, "Sign out"
    assert_select "[data-flat-pack--icon-name-value='x-mark']", count: 1
    assert_select "a[href='/recording_studio_presskits/press_kits'][aria-label='Close']", count: 1

    get recording_studio_presskits.press_kits_path(view: "table")
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "<table"
  end

  test "empty index explains what to do next" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_includes response.body, "Nothing here yet"
    assert_includes response.body, "Make a press kit"
  end

  test "kit show walks children in order and renders host components" do
    kit = record_kit("Spring launch")
    record_block(kit, "Hero")
    record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kit_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Hero"
    assert_includes response.body, "Quotes"
    assert_match(/Hero.*Quotes/m, response.body)
    refute_includes response.body, "Dummy host"
  end

  test "empty kit shows no sections yet and the picker" do
    kit = record_kit("Empty launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "No sections yet"
    assert_includes response.body, "presskits-section-picker"
  end

  test "picker adds a fake block under the kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { FakeBlock.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit), params: { type: "FakeBlock" }
    end

    follow_redirect!
    assert_response :success
    child = kit.recording_studio_orderable_children.last
    assert_equal kit, child.parent_recording
    assert_equal "Fake block", child.recordable.title
  end

  test "remove trashes a child through trashable" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    sign_in @user
    switch_to_root(@root)

    delete recording_studio_presskits.press_kit_section_path(kit, hero)
    follow_redirect!

    assert_response :success
    refute_includes response.body, "Hero"
    refute_includes RecordingStudioPresskits::KitQuery.live_children(kit).map(&:id), hero.id
    assert hero.reload.trashed_at.present?
  end

  test "reorder moves children through orderable" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    quotes = record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      ordered_recording_ids: [quotes.id, hero.id]
    }
    follow_redirect!

    assert_response :success
    assert_equal [quotes.id, hero.id], kit.recording_studio_orderable_children.map(&:id)
  end

  test "creating a kit uses record and lands on the editor" do
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::PressKit.count }, 1 do
      post recording_studio_presskits.press_kits_path, params: { press_kit: { title: "Autumn recap" } }
    end

    kit = RecordingStudio::Recording.find_by!(recordable: RecordingStudioPresskits::PressKit.find_by!(title: "Autumn recap"))
    assert_redirected_to recording_studio_presskits.press_kit_path(kit)
    assert_equal @root, kit.parent_recording
  end

  test "unauthenticated visitors are sent to sign in" do
    get recording_studio_presskits.press_kits_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated users without access are forbidden" do
    outsider = User.create!(
      email: "no-access-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :forbidden
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
end
