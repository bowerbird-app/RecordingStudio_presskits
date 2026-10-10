# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "visibility-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Visibility Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "new kits are public by default and anonymous visitors see the full published kit" do
    kit = record_kit("Spring launch")
    record_block(kit, "Hero")
    publish_kit!(kit, slug: "spring-launch-public")

    assert_equal :public, RecordingStudioPresskits::Visibility.effective_audience(kit)
    assert_equal :preview, RecordingStudioPresskits::KitSettings.fallback_for(kit)
    assert_equal :full, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)

    get kit.publishable_public_path
    assert_response :success
    assert_blank_public_layout
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Hero"
    refute_includes response.body, "Sign in to view the full kit"
    refute_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "signed_in audience with preview shows the allowlist and a sign-in link" do
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-signed-in")
    record_block(kit, "Secret notes")

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='preview']"
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Doors at noon."
    assert_includes response.body, "Sign in to view the full kit"
    assert_select "a[href='/users/sign_in']", text: "Sign in"
    refute_includes response.body, "Secret notes"
    assert_select "#presskits-public-sections", count: 0
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_select "meta[name='robots'][content='noindex, nofollow']"
    assert_select "meta[name='description'][content='Doors at noon.']"
    refute_includes response.body, "og:description\" content=\"Secret"
  end

  test "granted audience with preview asks for access and skips the sign-in button" do
    kit = restrict_kit("Spring launch", audience: :granted, fallback: :preview, slug: "spring-granted")
    record_block(kit, "Secret notes")

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='preview']"
    assert_includes response.body, "You need access to view the full kit"
    refute_includes response.body, "Sign in to view the full kit"
    refute_select "a[href='/users/sign_in']"
    refute_includes response.body, "Secret notes"
  end

  test "custom journalist audience with preview uses the access message" do
    kit = restrict_kit(
      "Spring launch",
      audience: :"presskits.verified_journalist",
      fallback: :preview,
      slug: "spring-journalist"
    )
    record_block(kit, "Embargo copy")

    get kit.publishable_public_path
    assert_response :success
    assert_includes response.body, "You need access to view the full kit"
    refute_includes response.body, "Embargo copy"

    journalist = User.create!(
      email: "desk-#{SecureRandom.hex(4)}@journalists.example",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in journalist

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Embargo copy"
  end

  test "hidden fallback 404s without confirming the kit" do
    kit = restrict_kit("Spring launch", audience: :granted, fallback: :hidden, slug: "spring-hidden")
    record_block(kit, "Secret notes")

    get kit.publishable_public_path
    assert_response :not_found
    refute_includes response.body, "Spring launch"
    refute_includes response.body, "Secret notes"
    refute_includes response.body, "Press kit"
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "signed-in visitor with signed_in audience sees the full kit" do
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-member")
    record_block(kit, "Hero")
    visitor = User.create!(
      email: "member-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in visitor

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Hero"
  end

  test "granted visitor with a view grant sees the full kit" do
    kit = restrict_kit("Spring launch", audience: :granted, fallback: :hidden, slug: "spring-invite")
    record_block(kit, "Hero")
    guest = User.create!(
      email: "guest-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    result = RecordingStudioAccessible.grant_access(recording: @root, actor: guest, role: :view, manager_actor: @user)
    raise result.error if result.failure?
    sign_in guest

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
    assert_includes response.body, "Hero"
  end

  test "draft kits stay unavailable even when the audience is public" do
    kit = record_kit("Autumn recap")
    publish_kit!(kit, slug: "autumn-recap-draft", status: "draft")

    assert_equal :unavailable, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
    get "/published/#{kit.publishable_child_recording.id}/autumn-recap-draft"
    assert_response :not_found

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "Autumn recap"
    assert_includes response.body, "This is just for you"
  end

  test "owner editor still opens a hidden published kit" do
    kit = restrict_kit("Spring launch", audience: :granted, fallback: :hidden, slug: "spring-owner")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_includes response.body, "Spring launch"

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='full']"
  end

  test "visibility editor lists allowed audiences and hides fallback while public" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    visibility_path = recording_studio_presskits.edit_press_kit_visibility_path(kit)
    assert_select "#presskits-kit-header [role='menuitem'][href='#{visibility_path}'][aria-label='Who can see this']"

    get visibility_path, headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_select "select[name='visibility[audience]'] option[value='public']"
    assert_select "select[name='visibility[audience]'] option[value='signed_in']"
    assert_select "select[name='visibility[audience]'] option[value='granted']"
    assert_select "select[name='visibility[audience]'] option[value='presskits.verified_journalist']"
    assert_select "[data-recording-studio-presskits--visibility-fallback-target='fallback'][hidden]"
    assert_select "input[name='visibility[visibility_fallback]'][value='preview']"
  end

  test "restricting then returning to public keeps the stored fallback" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_visibility_path(kit), params: {
      visibility: { audience: "signed_in", visibility_fallback: "hidden" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_visibility_path(kit)
    kit.reload
    assert_equal :signed_in, RecordingStudioPresskits::Visibility.effective_audience(kit)
    assert_equal :hidden, RecordingStudioPresskits::KitSettings.fallback_for(kit)

    get recording_studio_presskits.edit_press_kit_visibility_path(kit)
    assert_response :success
    refute_select "[data-recording-studio-presskits--visibility-fallback-target='fallback'][hidden]"
    assert_select "input[name='visibility[visibility_fallback]'][value='hidden']"

    patch recording_studio_presskits.press_kit_visibility_path(kit), params: {
      visibility: { audience: "public", visibility_fallback: "hidden" }
    }
    kit.reload
    assert_equal :public, RecordingStudioPresskits::Visibility.effective_audience(kit)
    assert_equal :hidden, RecordingStudioPresskits::KitSettings.fallback_for(kit)
  end

  test "host allowed list falls back to granted and the editor shows that audience" do
    audiences = RecordingStudioAccessible.configuration.action_audiences
    previous = audiences[:"presskits.kit_view_full"]
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-host")
    audiences[:"presskits.kit_view_full"] = previous.merge(allowed: %i[granted])

    assert_equal :granted, RecordingStudioPresskits::Visibility.effective_audience(kit.reload)
    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_visibility_path(kit)
    assert_response :success
    assert_select "select[name='visibility[audience]'] option[selected][value='granted']"
    refute_select "select[name='visibility[audience]'] option[value='public']"
    refute_select "select[name='visibility[audience]'] option[value='signed_in']"
  ensure
    RecordingStudioAccessible.configuration.action_audiences[:"presskits.kit_view_full"] = previous if previous
  end

  test "workspace constraint falls back to granted and the editor shows that audience" do
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-constrained")

    RecordingStudioAccessible.set_audience_constraint!(
      root: @root,
      action: :"presskits.kit_view_full",
      allowed_audiences: %i[granted],
      actor: @user
    )

    assert_equal :granted, RecordingStudioPresskits::Visibility.effective_audience(kit.reload)
    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_visibility_path(kit)
    assert_response :success
    assert_select "select[name='visibility[audience]'] option[selected][value='granted']"
    refute_select "select[name='visibility[audience]'] option[value='public']"
    refute_select "select[name='visibility[audience]'] option[value='signed_in']"
    assert_includes response.body, "Your workspace only allows some of these choices"
  end

  test "hidden kits are omitted from public discovery and stay on the owner listing" do
    visible = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-listed")
    hidden = restrict_kit("Quiet launch", audience: :granted, fallback: :hidden, slug: "quiet-listed")
    record_block(visible, "Hero")

    discovered = RecordingStudioPresskits::KitQuery.discoverable_for(actor: nil).map(&:id)
    assert_includes discovered, visible.id
    refute_includes discovered, hidden.id

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "Quiet launch"
  end

  test "changing fallback does not revise the press kit recordable" do
    kit = record_kit("Spring launch")
    recordable_id = kit.recordable_id

    RecordingStudioPresskits::KitSettings.save_fallback!(
      recording: kit,
      fallback: :hidden,
      actor: @user
    )
    kit.reload

    assert_equal recordable_id, kit.recordable_id
    assert_equal :hidden, RecordingStudioPresskits::KitSettings.fallback_for(kit)
    assert_equal 1, kit.events.where(action: "visibility_fallback_changed").count
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
    @root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = title
      press_kit.description = "Doors at noon."
    end
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      title: title,
      actor: @user
    )
  end

  def publish_kit!(kit, slug:, status: "published")
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: slug, status: status, meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end

  def restrict_kit(title, audience:, fallback:, slug:)
    kit = record_kit(title)
    publish_kit!(kit, slug: slug)
    RecordingStudioPresskits::Visibility.set_audience!(
      recording: kit,
      audience: audience,
      actor: @user
    )
    RecordingStudioPresskits::KitSettings.save_fallback!(
      recording: kit,
      fallback: fallback,
      actor: @user
    )
    kit.reload
  end
end
