# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitBrandingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  BRANDED_STYLE = [
    "--color-primary: #0F766E",
    "--color-primary-text: #F8FAFC",
    "--color-primary-hover: #115E59",
    "--button-primary-background-color: #0F766E",
    "--button-primary-hover-background-color: #115E59",
    "--button-primary-text-color: #F8FAFC",
    "--button-primary-border-color: #0F766E",
    "--color-ring: #0F766E",
    "--button-focus-ring-color: #0F766E",
    "font-family: Georgia, serif"
  ].join("; ").freeze

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "brand-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Brand Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?

    @kit = record_kit("Spring launch")
    @root.revise(@kit) { |press_kit| press_kit.cover_color = "#BFDBFE" }
    @kit.reload
    record_block(@kit, "Hero")
    publish_kit!(@kit, slug: "spring-launch-brand")
  end

  teardown do
    remove_press_centers
    Current.actor = @previous_actor
  end

  test "a branded public page and kit embed use one wrapper each" do
    install_press_centers(BRANDED_STYLE)

    get @kit.publishable_public_path
    assert_response :success
    assert_branded_frame("presskits-public-page")
    assert_select "#presskits-kit-embed", count: 0
    assert_cover_keeps_its_own_colours
    assert_equal @kit.id, RecordingStudioPressCenters.kit_recording.id

    get kit_embed_path(@kit)
    assert_response :success
    assert_branded_frame("presskits-kit-embed")
    assert_select "#presskits-public-page", count: 0
    assert_cover_keeps_its_own_colours
  end

  test "nil branding leaves the flatpack theme on the public page and the embed" do
    install_press_centers(nil)

    get @kit.publishable_public_path
    assert_response :success
    assert_unbranded_frame("presskits-public-page")

    get kit_embed_path(@kit)
    assert_response :success
    assert_unbranded_frame("presskits-kit-embed")
  end

  test "a public page and embed stay on the flatpack theme when press centers is not loaded" do
    remove_press_centers

    get @kit.publishable_public_path
    assert_response :success
    assert_unbranded_frame("presskits-public-page")

    get kit_embed_path(@kit)
    assert_response :success
    assert_unbranded_frame("presskits-kit-embed")
  end

  test "the kit editor and owner preview do not take the press center brand" do
    install_press_centers(BRANDED_STYLE)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(@kit)
    assert_response :success
    refute_includes response.body, BRANDED_STYLE
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0

    get recording_studio_presskits.preview_press_kit_path(@kit)
    assert_response :success
    refute_includes response.body, BRANDED_STYLE
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0
  end

  private

  def assert_branded_frame(id)
    assert_select "##{id}", count: 1
    frame = css_select("##{id}").first
    assert_equal BRANDED_STYLE, frame["style"]
    assert_nil css_select("html").first["style"]
    assert_select "##{id} #presskits-cover-hero"
  end

  def assert_unbranded_frame(id)
    assert_select "##{id}", count: 1
    assert_nil css_select("##{id}").first["style"]
    assert_nil css_select("html").first["style"]
    refute_includes response.body, BRANDED_STYLE
    refute_includes response.body, "#0F766E"
    assert_cover_keeps_its_own_colours
  end

  def assert_cover_keeps_its_own_colours
    hero = css_select("#presskits-cover-hero").first
    assert_equal "#BFDBFE", hero["data-cover-color"]
    refute_includes hero["style"].to_s, "#0F766E"
    refute_includes hero["style"].to_s, "font-family"
    assert_equal "#BFDBFE", @kit.reload.recordable.cover_color
    assert_nil @kit.recordable.cover_text_color
  end

  def install_press_centers(style)
    remove_press_centers
    mod = Module.new
    mod.define_singleton_method(:branding_for) do |kit_recording|
      mod.instance_variable_set(:@kit_recording, kit_recording)
      return if style.nil?

      Struct.new(:style_attribute).new(style)
    end
    mod.define_singleton_method(:kit_recording) { instance_variable_get(:@kit_recording) }
    Object.const_set(:RecordingStudioPressCenters, mod)
  end

  def remove_press_centers
    return unless defined?(RecordingStudioPressCenters)

    Object.send(:remove_const, :RecordingStudioPressCenters)
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
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      title: title,
      actor: @user
    )
  end

  def publish_kit!(kit, slug:)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: slug, status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end
end
