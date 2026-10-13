# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitBrandingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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
    record_block(@kit, "Hero")
    publish_kit!(@kit, slug: "spring-launch-brand")
  end

  teardown do
    remove_press_centers
    Current.actor = @previous_actor
  end

  test "a public page and kit embed inherit the press center one field at a time" do
    install_center(brand_color: "#0F766E", font_family: "serif")

    get @kit.publishable_public_path
    assert_response :success
    assert_inherited_frame("presskits-public-page")
    assert_select "#presskits-kit-embed", count: 0
    assert_nil css_select("html").first["style"]
    assert_equal @kit.id, RecordingStudioPressCenters.kit_recording.id
    assert_nil @kit.reload.recordable.brand_color
    assert_nil @kit.recordable.font_family

    get kit_embed_path(@kit)
    assert_response :success
    assert_inherited_frame("presskits-kit-embed")
    assert_select "body[data-recording-studio-default-layout]"
    assert_select "[data-presskits-blank-layout]", count: 0
    assert_select "#presskits-public-page", count: 0
  end

  test "an explicit kit default beats the press center on the public page" do
    install_center(brand_color: "#0F766E", font_family: "serif")
    @root.revise(@kit) do |press_kit|
      press_kit.brand_color = "#333333"
      press_kit.font_family = "sans"
    end
    publish_kit!(@kit.reload, slug: "spring-launch-brand")

    get @kit.publishable_public_path
    assert_response :success
    frame = css_select("#presskits-public-page").first
    assert_includes frame["style"], "--color-primary: #333333"
    assert_includes frame["style"], "font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif"
    refute_includes frame["style"], "#0F766E"
    refute_includes frame["style"], "Georgia"
  end

  test "a blank center still paints the flatpack default" do
    install_center(brand_color: nil, font_family: nil)

    get @kit.publishable_public_path
    assert_response :success
    assert_default_frame("presskits-public-page")

    get kit_embed_path(@kit)
    assert_response :success
    assert_default_frame("presskits-kit-embed")
  end

  test "a public page and embed use the local tokens when press centers is not loaded" do
    remove_press_centers

    get @kit.publishable_public_path
    assert_response :success
    assert_default_frame("presskits-public-page")

    get kit_embed_path(@kit)
    assert_response :success
    assert_default_frame("presskits-kit-embed")
  end

  test "the kit editor and owner preview do not wrap with the public brand frame" do
    install_center(brand_color: "#0F766E", font_family: "serif")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(@kit)
    assert_response :success
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0

    get recording_studio_presskits.preview_press_kit_path(@kit)
    assert_response :success
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0
  end

  test "header brand tabs follow the stored source and save both fields together" do
    install_center(brand_color: "#0F766E", font_family: "serif")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(@kit)
    assert_response :success
    assert_select "button#presskits-brand-press-center-tab[aria-selected='true']", text: "Press center"
    assert_select "button#presskits-brand-custom-tab[aria-selected='false']", text: "Custom"
    assert_select "input#press_kit_brand_source[value='press_center']"
    assert_select "[data-presskits-brand-inherited]", text: "Serif · #0F766E"
    assert_equal "#0F766E", css_select("input[name='press_kit[brand_color]']").first["value"].upcase
    assert_equal(
      RecordingStudioPresskits::BrandStyle.swatch_css_for("serif"),
      css_select("input[name='press_kit[font_family]']").first["value"]
    )
    refute_select "#presskits-header-edit-preview"

    @root.revise(@kit) { |press_kit| press_kit.brand_color = "#DB2777" }
    get recording_studio_presskits.edit_press_kit_header_path(@kit)
    assert_response :success
    assert_select "button#presskits-brand-custom-tab[aria-selected='true']"
    assert_select "input#press_kit_brand_source[value='custom']"
    assert_equal "#DB2777", css_select("input[name='press_kit[brand_color]']").first["value"].upcase
    assert_equal(
      RecordingStudioPresskits::BrandStyle.swatch_css_for("serif"),
      css_select("input[name='press_kit[font_family]']").first["value"]
    )

    patch recording_studio_presskits.press_kit_header_path(@kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "custom",
        brand_color: "#333333",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("sans")
      }
    }
    assert_equal "#333333", @kit.reload.recordable.brand_color
    assert_equal "sans", @kit.recordable.font_family

    patch recording_studio_presskits.press_kit_header_path(@kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "press_center",
        brand_color: "#DB2777",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("mono")
      }
    }
    assert_nil @kit.reload.recordable.brand_color
    assert_nil @kit.recordable.font_family
  end

  private

  def assert_inherited_frame(id)
    assert_select "##{id}", count: 1
    frame = css_select("##{id}").first
    assert_includes frame["style"], "--color-primary: #0F766E"
    assert_includes frame["style"], "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast.text_on('#0F766E')}"
    assert_includes frame["style"], "--button-primary-background-color: var(--color-primary)"
    assert_includes frame["style"], "font-family: ui-serif, Georgia, Cambria, Times New Roman, serif"
    assert_select "##{id} #presskits-kit-cover"
  end

  def assert_default_frame(id)
    assert_select "##{id}", count: 1
    frame = css_select("##{id}").first
    assert_includes frame["style"], "--color-primary: #333333"
    assert_includes frame["style"], "font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif"
    refute_includes frame["style"], "#0F766E"
    assert_nil css_select("html").first["style"]
  end

  def install_center(brand_color:, font_family:)
    remove_press_centers
    center = Struct.new(:brand_color, :font_family).new(brand_color, font_family)
    mod = Module.new
    mod.define_singleton_method(:branding_for) do |kit_recording|
      mod.instance_variable_set(:@kit_recording, kit_recording)
      center
    end
    mod.define_singleton_method(:kit_recording) { instance_variable_get(:@kit_recording) }
    mod.const_set(:Branding, Class.new(RecordingStudioPresskits::BrandStyle))
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
