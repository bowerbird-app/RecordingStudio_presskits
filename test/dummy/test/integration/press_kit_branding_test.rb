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

  test "kit previews carry the brand style and editor chrome does not" do
    install_center(brand_color: "#0F766E", font_family: "serif")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(@kit)
    assert_response :success
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0
    assert_branded_preview("presskits-editor-preview")
    assert_select "#presskits-editor-toolbar[data-presskits-brand]", count: 0
    assert_nil css_select("#presskits-editor-toolbar").first["style"]
    assert_select "#presskits-editor-toolbar #presskits-section-picker"
    assert_neutral_controls("#presskits-kit-header .#{RecordingStudioPresskits::BrandStyle::NEUTRAL_CLASS}")
    assert_select "[data-presskits-section-actions].#{RecordingStudioPresskits::BrandStyle::NEUTRAL_CLASS}"
    refute_includes css_select("#presskits-editor-toolbar").first.to_html, "--color-primary: #0F766E"

    get recording_studio_presskits.edit_press_kit_header_path(@kit)
    assert_response :success
    assert_select "[data-presskits-brand]", count: 0
    assert_select "#presskits-header-form"
    assert_select "#presskits-header-actions"
    refute_includes css_select("#presskits-header-form").first.to_html, "--color-primary: #0F766E"

    get recording_studio_presskits.preview_press_kit_path(@kit)
    assert_response :success
    assert_select "#presskits-public-page", count: 0
    assert_select "#presskits-kit-embed", count: 0
    assert_branded_preview("presskits-owner-preview")
  end

  test "a light brand uses dark text on the public page and the audience preview" do
    @root.revise(@kit) { |press_kit| press_kit.brand_color = "#FDE68A" }
    publish_kit!(@kit.reload, slug: "spring-launch-brand")
    text = RecordingStudioPresskits::Cover::Contrast::DARK

    get @kit.publishable_public_path
    assert_response :success
    frame = css_select("#presskits-public-page").first
    assert_includes frame["style"], "--color-primary: #FDE68A"
    assert_includes frame["style"], "--color-primary-text: #{text}"
    assert_includes frame["style"], "--button-primary-text-color: var(--color-primary-text)"
    assert_includes response.body, "recording_studio_presskits/brand_buttons"

    RecordingStudioPresskits::Visibility.set_audience!(
      recording: @kit,
      actor: @user,
      audience: :signed_in
    )
    RecordingStudioPresskits::KitSettings.save_fallback!(
      recording: @kit,
      fallback: :preview,
      actor: @user
    )
    get @kit.publishable_public_path
    assert_response :success
    preview = css_select("#presskits-public-preview").first
    assert_equal "true", preview["data-presskits-brand"]
    assert_includes preview["style"], "--color-primary: #FDE68A"
    assert_includes preview["style"], "--color-primary-text: #{text}"
    assert_select "#presskits-public-preview a[data-fp-style='primary']", text: "Sign in"
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

  test "button text and corners inherit, then a kit value wins, and square zeroes the radii" do
    install_center(brand_color: "#0F766E", font_family: "serif", text_color: "#111827", corner_style: "square")
    auto = RecordingStudioPresskits::Cover::Contrast.text_on("#0F766E")

    get @kit.publishable_public_path
    assert_response :success
    frame = css_select("#presskits-public-page").first
    assert_includes frame["style"], "--color-primary-text: #111827"
    assert_includes frame["style"], "--radius-sm: 0"
    assert_includes frame["style"], "--radius-md: 0"
    assert_includes frame["style"], "--radius-lg: 0"
    assert_includes frame["style"], "--radius-xl: 0"
    assert_includes frame["style"], "--button-border-radius: 0"
    refute_includes frame["style"], auto
    cover = css_select("[data-cover-card]").first.parent
    assert_includes cover["style"], "--color-primary-text: #111827"
    assert_includes cover["style"], "--button-border-radius: 0"
    refute_includes cover["style"], auto

    @root.revise(@kit) do |press_kit|
      press_kit.text_color = "#111827"
      press_kit.corner_style = "rounded"
    end
    get @kit.publishable_public_path
    frame = css_select("#presskits-public-page").first
    assert_includes frame["style"], "--color-primary-text: #111827"
    refute_includes frame["style"], "--radius-lg: 0"
    refute_includes frame["style"], "--button-border-radius: 0"
  end

  test "the header stores button text and corners, and press center clears them" do
    install_center(brand_color: "#0F766E", font_family: "serif", text_color: "#F8FAFC", corner_style: "square")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(@kit)
    assert_response :success
    assert_select "input[name='press_kit[text_color]'][type='color']"
    assert_select "input[name='press_kit[corner_style]'][value='square'][checked]"
    assert_select "input[name='press_kit[corner_style]'][value='rounded']"
    assert_includes response.body, "stop-circle"
    assert_equal "#F8FAFC", css_select("input[name='press_kit[text_color]']").first["value"].upcase

    patch recording_studio_presskits.press_kit_header_path(@kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "custom",
        brand_color: "#DB2777",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("mono"),
        text_color: "#111827",
        corner_style: "rounded"
      }
    }
    assert_equal "#111827", @kit.reload.recordable.text_color
    assert_equal "rounded", @kit.recordable.corner_style

    patch recording_studio_presskits.press_kit_header_path(@kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "press_center",
        brand_color: "#DB2777",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("mono"),
        text_color: "#111827",
        corner_style: "rounded"
      }
    }
    assert_nil @kit.reload.recordable.text_color
    assert_nil @kit.recordable.corner_style
    assert_nil @kit.recordable.brand_color
  end

  private

  def assert_branded_preview(id)
    assert_select "##{id}[data-presskits-brand='true']", count: 1
    frame = css_select("##{id}").first
    assert_includes frame["style"], "--color-primary: #0F766E"
    assert_includes frame["style"], "--color-primary-hover: oklch(from var(--color-primary) calc(l - 0.1) c h)"
    assert_includes frame["style"], "--color-primary-active: oklch(from var(--color-primary) calc(l - 0.16) c h)"
    assert_includes frame["style"], "--button-primary-active-background-color: var(--color-primary-active)"
    assert_includes frame["style"], "--button-focus-ring-color: var(--color-primary)"
    assert_includes frame["style"], "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast.text_on('#0F766E')}"
  end

  def assert_neutral_controls(selector)
    control = css_select(selector).first
    assert control, "expected #{selector}"
    assert_includes control["class"], RecordingStudioPresskits::BrandStyle::NEUTRAL_CLASS
    assert_includes control["style"], "--color-primary: oklch(var(--brand-lightness) var(--brand-chroma) var(--brand-hue))"
    refute_includes control["style"], "#0F766E"
  end

  def assert_inherited_frame(id)
    assert_select "##{id}", count: 1
    frame = css_select("##{id}").first
    assert_equal "true", frame["data-presskits-brand"]
    assert_includes frame["style"], "--color-primary: #0F766E"
    assert_includes frame["style"], "--color-primary-text: #{RecordingStudioPresskits::Cover::Contrast.text_on('#0F766E')}"
    assert_includes frame["style"], "--color-primary-hover: oklch(from var(--color-primary) calc(l - 0.1) c h)"
    assert_includes frame["style"], "--color-primary-active: oklch(from var(--color-primary) calc(l - 0.16) c h)"
    assert_includes frame["style"], "--button-primary-active-background-color: var(--color-primary-active)"
    assert_includes frame["style"], "--button-focus-ring-color: var(--color-primary)"
    assert_includes frame["style"], "--button-primary-background-color: var(--color-primary)"
    assert_includes frame["style"], "font-family: ui-serif, Georgia, Cambria, Times New Roman, serif"
    assert_select "##{id} #presskits-kit-cover"
    assert_nil css_select("html").first["style"]
  end

  def assert_default_frame(id)
    assert_select "##{id}", count: 1
    frame = css_select("##{id}").first
    assert_equal "true", frame["data-presskits-brand"]
    assert_includes frame["style"], "--color-primary: #333333"
    assert_includes frame["style"], "--color-primary-active: oklch(from var(--color-primary) calc(l - 0.16) c h)"
    assert_includes frame["style"], "font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif"
    refute_includes frame["style"], "#0F766E"
    assert_nil css_select("html").first["style"]
  end

  def install_center(brand_color:, font_family:, text_color: nil, corner_style: nil)
    remove_press_centers
    center = Struct.new(:brand_color, :font_family, :text_color, :corner_style).new(
      brand_color, font_family, text_color, corner_style
    )
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
