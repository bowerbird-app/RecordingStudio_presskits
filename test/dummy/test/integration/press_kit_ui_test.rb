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
    assert_access_slot_only
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
    assert_includes response.body, "New press kit"
    assert_match(/New press kit.*squares-2x2.*table-cells/m, response.body)
    assert_select "a[aria-label='Cards'] [data-flat-pack--icon-name-value='squares-2x2']", count: 1
    assert_select "a[aria-label='Table'] [data-flat-pack--icon-name-value='table-cells']", count: 1
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
    assert_page_nav_close
    assert_access_slot_only

    get recording_studio_presskits.press_kits_path(view: "table")
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "<table"
    assert_match(/New press kit.*squares-2x2.*table-cells/m, response.body)
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
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
    assert_page_nav_close
    assert_access_slot_only
    refute_includes response.body, "presskits-section-picker"
    refute_includes response.body, "Add a section"
    refute_includes response.body, "Dummy host"
  end

  test "new press kit form renders the PageNav close X" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.new_press_kit_path
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "New press kit"
    assert_page_nav_close
    assert_access_slot_only
  end

  test "kit edit shows the title form and add dropdown without the picker card" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Add the bits you need"
    assert_includes response.body, "presskits-section-dropdown"
    assert_includes response.body, "Add a section"
    assert_includes response.body, "Preview"
    assert_includes response.body, 'name="press_kit[title]"'
    refute_includes response.body, "presskits-section-picker"
    refute_includes response.body, "Pick what to drop into this kit."
    refute_includes response.body, "Fake block"
    refute_includes response.body, "No sections yet"
    refute_includes response.body, "role=\"menu\""
    assert_access_slot_only
    assert_includes response.body, "items-start"
    assert_match(/EditButtonComponent|Published|Draft/, response.body)
  end

  test "empty kit editor keeps add, preview, and publishable on one row" do
    kit = record_kit("Empty launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "presskits-section-dropdown"
    assert_includes response.body, "Preview"
    refute_includes response.body, "No sections yet"
    refute_includes response.body, "presskits-section-picker"
    refute_includes response.body, "Fake block"
    refute_includes response.body, "role=\"menu\""
  end

  test "dropdown rejects dummy fake block types" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_no_difference -> { FakeBlock.count } do
      post recording_studio_presskits.press_kit_sections_path(kit), params: { type: "FakeBlock" }
    end

    follow_redirect!
    assert_response :success
    assert_match(/That section isn(?:'|&#39;)t on the list/, response.body)
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

    title = "Winter brief #{SecureRandom.hex(4)}"
    assert_difference -> { RecordingStudioPresskits::PressKit.count }, 1 do
      post recording_studio_presskits.press_kits_path, params: { press_kit: { title: title } }
    end

    press_kit = RecordingStudioPresskits::PressKit.where(title: title).order(:created_at).last
    kit = RecordingStudioPresskits::KitQuery.for_root(@root).find { |recording| recording.recordable_id == press_kit.id }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert_equal @root, kit.parent_recording
  end

  test "saving the kit title uses revise" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_path(kit), params: { press_kit: { title: "Spring launch, take two" } }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Spring launch, take two"
    assert_equal "Spring launch, take two", kit.reload.recordable.title
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
