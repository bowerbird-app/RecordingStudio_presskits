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
    refute_includes response.body, "You must be signed in to Harbour Studio to view this press kit."
    refute_includes response.body, "See full press kit"
    refute_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "signed_in audience with preview shows the allowlist and a sign-in link" do
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-signed-in")
    record_block(kit, "Secret notes")

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='preview']"
    assert_includes response.body, "Spring launch"
    refute_includes response.body, "Doors at noon."
    refute_select "[data-presskits-preview-description]"
    assert_includes response.body, "See full press kit"
    assert_includes response.body, "You must be signed in to Harbour Studio to view this press kit."
    assert_select "a[href='/users/sign_in']", text: "Sign in"
    assert_select "a[href='/users/sign_up']", text: "Create account"
    refute_includes response.body, "Sign in to view the full kit"
    refute_includes response.body, "data-presskits-preview-date"
    refute_select "[role='alert']"
    refute_includes response.body, "Secret notes"
    assert_select "#presskits-public-sections", count: 0
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_select "meta[name='robots'][content='noindex, nofollow']"
    refute_select "meta[name='description']"
    refute_includes response.body, "og:description"
  end

  test "granted audience with preview asks for access and skips the sign-in button" do
    kit = restrict_kit("Spring launch", audience: :granted, fallback: :preview, slug: "spring-granted")
    record_block(kit, "Secret notes")

    get kit.publishable_public_path
    assert_response :success
    assert_select "[data-presskits-presentation='preview']"
    assert_includes response.body, "Spring launch"
    refute_includes response.body, "Doors at noon."
    refute_select "[data-presskits-preview-description]"
    assert_includes response.body, "See full press kit"
    assert_includes response.body, "You need access to view this press kit."
    refute_includes response.body, "You must be signed in to Harbour Studio to view this press kit."
    refute_select "a[href='/users/sign_in']"
    refute_select "a[href='/users/sign_up']"
    refute_includes response.body, "Secret notes"
  end

  test "custom audience with preview uses the access message" do
    with_test_custom_audience do
      kit = restrict_kit(
        "Spring launch",
        audience: TEST_CUSTOM_AUDIENCE,
        fallback: :preview,
        slug: "spring-custom"
      )
      record_block(kit, "Embargo copy")

      get kit.publishable_public_path
      assert_response :success
      assert_includes response.body, "You need access to view this press kit."
      refute_includes response.body, "Embargo copy"

      member = User.create!(
        email: "desk-#{SecureRandom.hex(4)}@presskits.test",
        password: "Password123!",
        password_confirmation: "Password123!"
      )
      sign_in member

      get kit.publishable_public_path
      assert_response :success
      assert_select "[data-presskits-presentation='full']"
      assert_includes response.body, "Embargo copy"
    end
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

  test "anonymous visit after an editor request does not inherit leftover Current.actor" do
    preview_kit = restrict_kit(
      "Spring launch",
      audience: :signed_in,
      fallback: :preview,
      slug: "leftover-preview"
    )
    hidden_kit = restrict_kit(
      "Quiet launch",
      audience: :granted,
      fallback: :hidden,
      slug: "leftover-hidden"
    )
    record_block(preview_kit, "Secret notes")
    record_block(hidden_kit, "Embargo copy")

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(preview_kit)
    assert_response :success
    assert_equal @user, Current.actor

    sign_out :user
    Current.actor = @user

    without_host_current_actor do
      get preview_kit.publishable_public_path
      assert_response :success
      assert_select "[data-presskits-presentation='preview']"
      assert_includes response.body, "Spring launch"
      refute_includes response.body, "Secret notes"
      refute_includes response.body, "Doors at noon."
      assert_select "meta[name='robots'][content='noindex, nofollow']"
      refute_select "meta[name='description']"
      refute_includes response.body, "og:description"
      assert_equal "private, no-store", response.headers["Cache-Control"]

      get hidden_kit.publishable_public_path
      assert_response :not_found
      refute_includes response.body, "Quiet launch"
      refute_includes response.body, "Embargo copy"
      refute_includes response.body, "Press kit"
      assert_equal "private, no-store", response.headers["Cache-Control"]
    end
  end

  test "visibility editor lists allowed audiences and hides fallback while public" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    visibility_path = recording_studio_presskits.edit_press_kit_visibility_path(kit)
    downloads_path = recording_studio_presskits.edit_press_kit_downloads_path(kit)
    assert_select "#presskits-visibility[href='#{visibility_path}']", text: "Visibility"
    assert_select "#presskits-visibility[data-modal-id='pk-editor']"
    assert_select "#presskits-visibility[data-turbo-frame='pk-editor-screen']"
    assert_select "#presskits-editor-toolbar [data-flat-pack--icon-name-value='eye']"
    assert_select "#presskits-downloads[href='#{downloads_path}']", text: "Downloads"
    assert_select "#presskits-downloads [data-flat-pack--icon-name-value='arrow-down-tray']"
    toolbar_html = css_select("#presskits-editor-toolbar").to_html
    assert_operator toolbar_html.index("presskits-visibility"), :<, toolbar_html.index("presskits-downloads")
    refute_select "#presskits-kit-header [role='menuitem'][href='#{visibility_path}']"

    get visibility_path, headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_includes response.body, "Visibility"
    assert_includes response.body, "Who can view this press kit"
    assert_select "#presskits-visibility-form.max-w-xl"
    assert_select "select[name='visibility[audience]'] option[value='public']"
    assert_select "select[name='visibility[audience]'] option[value='signed_in']"
    assert_select "select[name='visibility[audience]'] option[value='granted']"
    refute_select "select[name='visibility[audience]'] option[value='presskits.verified_journalist']"
    refute_select "select[name='visibility[audience]'] option[value='#{TEST_CUSTOM_AUDIENCE}']"
    assert_select "[data-recording-studio-presskits--visibility-fallback-target='fallback'][hidden]"
    assert_select "input[name='visibility[visibility_fallback]'][value='preview']"
    assert_select "[data-flat-pack--icon-name-value='eye']"
    assert_select "[data-flat-pack--icon-name-value='eye-slash']"
    refute_includes response.body, "min-h-[7rem]"
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
    assert_select "h1", text: "Visibility"
    assert_includes response.body, "Who can view this press kit"
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

  test "preview hides create account when the host has no registration path" do
    previous = RecordingStudioPresskits.configuration.registration_path
    RecordingStudioPresskits.configuration.registration_path = nil
    kit = restrict_kit("Spring launch", audience: :signed_in, fallback: :preview, slug: "spring-no-register")

    get kit.publishable_public_path
    assert_response :success
    assert_select "a[href='/users/sign_in']", text: "Sign in"
    refute_select "a", text: "Create account"
  ensure
    RecordingStudioPresskits.configuration.registration_path = previous
  end

  private

  TEST_CUSTOM_AUDIENCE = :"presskits.test_custom"

  def with_test_custom_audience
    audiences = RecordingStudioAccessible.configuration.action_audiences
    previous = audiences[:"presskits.kit_view_full"]
    RecordingStudioAccessible.register_audience(TEST_CUSTOM_AUDIENCE) do |actor:, **|
      actor.respond_to?(:email) && actor.email.to_s.end_with?("@presskits.test")
    end

    audiences[:"presskits.kit_view_full"] = previous.merge(
      allowed: Array(previous[:allowed]) | [TEST_CUSTOM_AUDIENCE]
    )
    yield
  ensure
    audiences[:"presskits.kit_view_full"] = previous if previous
  end

  def without_host_current_actor
    ApplicationController.class_eval do
      alias_method :__presskits_original_set_current_actor, :set_current_actor
      define_method(:set_current_actor) { nil }
      private :set_current_actor
    end
    yield
  ensure
    ApplicationController.class_eval do
      alias_method :set_current_actor, :__presskits_original_set_current_actor
      remove_method :__presskits_original_set_current_actor
      private :set_current_actor
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
