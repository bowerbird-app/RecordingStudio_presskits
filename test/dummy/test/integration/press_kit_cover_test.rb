# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitCoverTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "cover-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Cover Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    remove_press_centers
    Current.actor = @previous_actor
  end

  test "a new kit inherits and resolves to the flatpack default" do
    kit = record_kit("Spring launch")

    assert_nil kit.recordable.brand_color
    assert_nil kit.recordable.font_family
    branding = RecordingStudioPresskits::KitBranding.for(kit)
    assert_equal "#333333", branding.brand_color
    assert_equal "sans", branding.font_family
  end

  test "brand colour and font must be usable and explicit defaults are stored" do
    kit = record_kit("Spring launch")

    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.brand_color = "blue" }
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.font_family = "comic" }
    end

    @root.revise(kit) do |press_kit|
      press_kit.brand_color = "#333333"
      press_kit.font_family = "sans"
    end
    kit.reload
    assert_equal "#333333", kit.recordable.brand_color
    assert_equal "sans", kit.recordable.font_family

    @root.revise(kit) { |press_kit| press_kit.brand_color = "#abc" }
    assert_equal "#AABBCC", kit.reload.recordable.brand_color
  end

  test "header editor shows font and colour swatches without inherit wording" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "input[name='press_kit[font_family]']"
    assert_select "input[name='press_kit[brand_color]'][type='color']"
    refute_includes response.body, "Inherit from press center"
    refute_select "[role='tab']"
    refute_select "input[name='press_kit[brand_source]']"
    refute_select "#presskits-header-edit-preview"
    refute_select "#presskits-cover-hero"
  end

  test "header save stores an explicit brand and inherit clears it" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "custom",
        brand_color: "#333333",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("sans")
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_equal "#333333", kit.reload.recordable.brand_color
    assert_equal "sans", kit.recordable.font_family

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch",
        brand_source: "press_center",
        brand_color: "#DB2777",
        font_family: RecordingStudioPresskits::BrandStyle::SWATCH_CSS.fetch("mono")
      }
    }
    assert_nil kit.reload.recordable.brand_color
    assert_nil kit.recordable.font_family
  end

  test "public kit and owner preview use the card, and the badge stays default" do
    kit = record_kit("Spring launch")
    @root.revise(kit) do |press_kit|
      press_kit.description = "Doors at noon."
      press_kit.brand_color = "#059669"
      press_kit.font_family = "serif"
    end
    record_block(kit, "Hero")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    refute_select "[data-presskits-inline-copy]"
    assert_select "#presskits-kit-cover [data-cover-title]", text: "Spring launch"
    assert_select "#presskits-kit-cover [data-cover-eyebrow]", text: "Press kit"
    assert_select "#presskits-kit-cover [data-cover-description]", text: "Doors at noon."
    public_copy = css_select("#presskits-kit-cover [data-cover-copy]").first
    assert_includes public_copy["class"], "@min-[640px]:pt-16"
    refute_includes public_copy["class"], "pt-12"
    public_body = css_select("#presskits-kit-cover [data-cover-row] > div").last
    assert_includes public_body["class"], "pt-7"
    refute_includes public_body["class"], "@min-[640px]:pt-16"
    refute_select "[data-presskits-header-actions]"
    refute_select "[data-presskits-header-image-actions]"
    refute_includes css_select("#presskits-kit-cover [data-cover-frame]").first.to_html, "Doors at noon."
    refute_select "#presskits-cover-hero"
    assert_default_eyebrow("#presskits-kit-cover [data-cover-eyebrow]", absent: "#059669")
    frame = css_select("#presskits-public-page").first
    assert_includes frame["style"], "--color-primary: #059669"
    assert_includes frame["style"], "font-family: ui-serif, Georgia, Cambria, Times New Roman, serif"
    public_preview = css_select("#presskits-public-preview").first
    assert_includes public_preview["class"], "gap-6"
    refute_includes public_preview["class"], "overflow-hidden"
    public_sections = css_select("#presskits-public-sections").first
    assert_includes public_sections["class"], "gap-6"
    refute_includes public_sections["class"], "p-5"
    section_card = css_select("#presskits-public-sections [data-section-card]").first
    assert_includes section_card["class"], "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
    assert_includes section_card["class"], "rounded-[var(--radius-lg)]"
    section_pad = css_select("#presskits-public-sections [data-section-card] > div").first
    assert_includes section_pad["class"], "pt-8"
    assert_includes section_pad["class"], "md:pt-10"
    assert_includes section_pad["class"], "lg:pt-12"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-title]", text: "Spring launch"
    assert_select "#presskits-kit-cover [data-cover-description]", text: "Doors at noon."
    refute_select "[data-presskits-header-actions]"
    refute_select "[data-presskits-header-image-actions]"
    refute_select "#presskits-public-page"
    refute_select "#presskits-cover-hero"
    preview = css_select("#presskits-public-preview").first
    assert_includes preview["class"], "gap-6"
    refute_includes preview["class"], "overflow-hidden"
    owner_card = css_select("#presskits-public-sections [data-section-card]").first
    assert_includes owner_card["class"], "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
    assert_includes owner_card["class"], "rounded-[var(--radius-lg)]"
  end

  test "hosts can override the card eyebrow" do
    I18n.t("recording_studio_presskits.cover.eyebrow")
    I18n.backend.store_translations(:en, recording_studio_presskits: { cover: { eyebrow: "Media kit" } })
    kit = record_kit("Spring launch")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-kit-cover [data-cover-eyebrow]", text: "Media kit"
  ensure
    I18n.backend.store_translations(:en, recording_studio_presskits: { cover: { eyebrow: "Press kit" } })
  end

  test "press kit payload reads stored brand fields and leaves nil as inherit" do
    kit = record_kit("Spring launch")

    assert_equal(
      { title: "Spring launch", subtitle: nil, description: nil, brand_color: nil, font_family: nil },
      RecordingStudioPresskits::Api::PressKitPayload.for(kit.recordable)
    )

    @root.revise(kit) do |press_kit|
      press_kit.subtitle = "Collection released"
      press_kit.description = "Doors at noon."
      press_kit.brand_color = "#BFDBFE"
      press_kit.font_family = "serif"
    end

    assert_equal(
      {
        title: "Spring launch",
        subtitle: "Collection released",
        description: "Doors at noon.",
        brand_color: "#BFDBFE",
        font_family: "serif"
      },
      RecordingStudioPresskits::Api::PressKitPayload.for(kit.reload.recordable)
    )
  end

  test "grid cards paint the view button from the kit brand and keep a default badge" do
    first = record_kit("Spring launch")
    second = record_kit("Autumn recap")
    @root.revise(first) do |press_kit|
      press_kit.subtitle = "Collection released"
      press_kit.brand_color = "#BFDBFE"
    end
    @root.revise(second) do |press_kit|
      press_kit.description = "A longer line that should clamp on the card."
      press_kit.brand_color = "#D97706"
      press_kit.font_family = "mono"
    end
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-card][data-brand-color='#BFDBFE']", count: 1
    assert_select "[data-cover-card][data-brand-color='#D97706']", count: 1
    assert_select "[data-cover-fallback]", count: 2
    assert_select "[data-cover-subtitle]", text: "Collection released"
    assert_select "[data-cover-description]", text: "A longer line that should clamp on the card."
    sky = css_select("[data-brand-color='#BFDBFE']").first
    amber = css_select("[data-brand-color='#D97706']").first
    assert_includes sky["style"], "--button-primary-background-color: #BFDBFE"
    assert_includes sky["style"], "--button-primary-text-color: #{RecordingStudioPresskits::Cover::Contrast.text_on('#BFDBFE')}"
    assert_includes amber["style"], "--button-primary-background-color: #D97706"
    sky_brand = sky.parent
    assert_equal "true", sky_brand["data-presskits-brand"]
    assert_includes sky_brand["style"], "--color-primary: #BFDBFE"
    assert_includes sky_brand["style"], "--color-primary-hover: oklch(from var(--color-primary) calc(l - 0.1) c h)"
    assert_includes sky_brand["style"], "--button-primary-active-background-color: var(--color-primary-active)"
    assert_includes sky_brand["style"], "--button-focus-ring-color: var(--color-primary)"
    refute_includes sky_brand["style"], "--button-primary-hover-background-color: #BFDBFE"
    assert_includes amber.to_html, "font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
    assert_default_eyebrow("[data-brand-color='#BFDBFE'] [data-cover-eyebrow]", absent: "#BFDBFE")
    assert_default_eyebrow("[data-brand-color='#D97706'] [data-cover-eyebrow]", absent: "#D97706")
    assert_select "a[data-cover-view][href='#{recording_studio_presskits.edit_press_kit_path(first)}']", text: /View/
    view = css_select("a[data-cover-view]").first
    assert_includes view.parent["class"], "mt-auto"
    assert_includes view.parent["class"], "pb-8"
    refute view.ancestors.any? { |node| node["data-cover-copy"] }
    copy = css_select("[data-cover-copy]").first
    assert_includes copy["class"], "@min-[640px]:pt-16"
    assert_includes copy["class"], "flex items-start gap-3"
    refute_includes copy["class"], "pt-12"
    body = css_select("[data-cover-row] > div").last
    assert_includes body["class"], "pt-7"
    refute_includes body["class"], "@min-[640px]:pt-16"
    assert_select ".grid.items-stretch"
    assert_select "a[data-cover-card]", count: 0
    assert_select "[data-cover-list] button[type=button] svg.w-6.h-6"

    RecordingStudioCompany.create(@root, actor: @user, name: "Harbour Studio")
    get recording_studio_presskits.press_kits_path
    assert_select "[data-cover-company]", text: "Harbour Studio", count: 2
    harbour = css_select("[data-cover-card][data-brand-color='#BFDBFE']").first.to_html
    assert_operator harbour.index("data-cover-company"), :<, harbour.index("data-cover-title")
    assert_operator harbour.index("gap-[14px]"), :<, harbour.index("data-cover-title")
  end

  test "the kit editor header is the wide card and the grid keeps the same markup" do
    first = record_kit("Spring launch")
    @root.revise(first) do |press_kit|
      press_kit.subtitle = "Collection released"
      press_kit.description = "Doors at noon."
      press_kit.brand_color = "#0F766E"
    end
    record_kit("Autumn recap")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-feature]", count: 0
    assert_select "[data-cover-card]", count: 2
    refute_select "[data-presskits-inline-copy]"
    refute_select "[data-presskits-header-actions]"
    refute_select "[data-presskits-header-image-actions]"
    refute_select "input[name='press_kit[title]']"
    grid_card = css_select("[data-cover-card]").first
    assert_includes grid_card["class"], "@container"
    assert_includes grid_card.to_html, "aspect-[430/368]"
    assert_includes grid_card.to_html, "@min-[640px]:flex-row"

    get recording_studio_presskits.edit_press_kit_path(first)
    assert_response :success
    header = css_select("#presskits-kit-header").first
    card = css_select("#presskits-kit-header [data-cover-card]").first
    assert_includes card["class"], "@container"
    row = css_select("#presskits-kit-header [data-cover-row]").first
    assert_includes row["class"], "flex-col"
    assert_includes row["class"], "@min-[640px]:flex-row"
    assert_includes row["class"], "@min-[640px]:min-h-[50cqw]"
    frame = css_select("#presskits-kit-header [data-cover-frame]").first
    assert_includes frame["class"], "aspect-[430/368]"
    assert_includes frame["class"], "@min-[640px]:w-1/2"
    assert_includes frame["class"], "@min-[640px]:aspect-auto"
    body = css_select("#presskits-kit-header [data-cover-row] > div").last
    assert_includes body["class"], "fp-overlay"
    assert_includes body["class"], "inline-flex"
    assert_includes body["class"], "flex-1"
    assert_includes body["class"], "flex-col"
    assert_includes body["class"], "px-8"
    assert_includes body["class"], "pt-7"
    assert_includes body["class"], "@min-[640px]:min-w-0"
    refute_includes body["class"], "@min-[640px]:pt-16"
    copy = css_select("#presskits-kit-header [data-cover-copy]").first
    assert_includes copy["class"], "pt-12"
    assert_includes copy["class"], "@min-[640px]:pt-16"
    actions = css_select("#presskits-kit-header [data-presskits-header-actions]").first
    refute actions.ancestors.any? { |node| node["data-cover-copy"] }
    assert_equal "top_right", actions.parent["data-fp-placement"]
    assert_equal "lg", actions.parent["data-fp-inset"]
    refute_includes actions.parent["class"], "flex-col-reverse"
    body_overlay = css_select("#presskits-kit-header [data-cover-body]").first
    assert_includes body_overlay["class"], "fp-overlay"
    assert_includes body_overlay["class"], "px-8"
    assert_includes body_overlay["class"], "pt-7"
    assert_select "#presskits-kit-header [data-cover-tag]", text: "Press kit"
    assert_default_eyebrow("#presskits-kit-header [data-cover-eyebrow]", absent: "#0F766E")
    assert_select "#presskits-kit-header [data-cover-title] h1", text: "Spring launch"
    assert_select "#presskits-kit-header [data-cover-subtitle]", text: "Collection released"
    assert_select "#presskits-kit-header [data-cover-description]", text: "Doors at noon."
    refute_includes frame.to_html, "Doors at noon."
    assert_select "#presskits-kit-header a[data-cover-view]", count: 0
    assert_select "#presskits-kit-header [data-presskits-inline-copy].relative.z-20"
    assert_select "#presskits-kit-header [data-flat-pack--inline-edit-required-value='true']"
    assert_select "#presskits-kit-header [data-presskits-header-actions] a[aria-label='Edit']"
    assert_select "#presskits-kit-header [data-presskits-header-image-actions] a[aria-label='Edit image']"
    badge = css_select("#presskits-kit-header [data-cover-tag]").first
    assert_equal "top_left", badge.parent["data-fp-placement"]
    image_actions = css_select("#presskits-kit-header [data-presskits-header-image-actions]").first
    assert_equal "top_right", image_actions.parent["data-fp-placement"]
    assert_equal "md", image_actions.parent["data-fp-inset"]
    refute_includes header.to_html, "Share"
    refute_includes header.to_html, "RELEASE DATE"
    refute_select "#presskits-cover-hero"
    section = css_select("#presskits-editor-sections").first
    refute_includes section.to_html, "@min-[640px]:flex-row"
  end

  test "the card heading is h1 or h2" do
    kit = record_kit("Spring launch")

    assert_equal :h2, RecordingStudioPresskits::Cover::Component.new(recording: kit).title_tag
    assert_equal :h2, RecordingStudioPresskits::Cover::Component.new(recording: kit, heading: :h3).title_tag
    assert_equal :h1, RecordingStudioPresskits::Cover::Component.new(recording: kit, heading: :h1).title_tag
  end

  test "the grid heart stays off without an actor" do
    kit = record_kit("Spring launch")
    component = RecordingStudioPresskits::Cover::Component.new(
      recording: kit,
      size: :card,
      href: "/kits/spring"
    )

    Current.actor = nil
    refute component.show_add_to_list?

    component.define_singleton_method(:lists_installed?) { false }
    Current.actor = @user
    refute component.show_add_to_list?
  end

  test "the header preview can leave the list heart off" do
    kit = record_kit("Spring launch")
    Current.actor = @user
    component = RecordingStudioPresskits::Cover::Component.new(recording: kit, add_to_list: false)

    refute component.show_add_to_list?
  end

  test "a kit brand wins over the press center one field at a time" do
    kit = record_kit("Spring launch")
    install_center(brand_color: "#0F766E", font_family: "serif")
    branding = RecordingStudioPresskits::KitBranding.for(kit)
    assert_equal "#0F766E", branding.brand_color
    assert_equal "serif", branding.font_family

    @root.revise(kit) { |press_kit| press_kit.font_family = "sans" }
    branding = RecordingStudioPresskits::KitBranding.for(kit.reload)
    assert_equal "#0F766E", branding.brand_color
    assert_equal "sans", branding.font_family

    @root.revise(kit) { |press_kit| press_kit.brand_color = "#333333" }
    branding = RecordingStudioPresskits::KitBranding.for(kit.reload)
    assert_equal "#333333", branding.brand_color
    assert_equal "sans", branding.font_family
  end

  private

  def assert_default_eyebrow(selector, absent:)
    badge = css_select(selector).first
    assert badge, "expected #{selector}"
    item = badge.parent
    assert_equal "top_left", item["data-fp-placement"]
    assert_equal "md", item["data-fp-inset"]
    assert_includes badge["class"], "bg-[var(--badge-default-background-color)]"
    assert_includes badge["class"], "text-[var(--badge-default-text-color)]"
    refute_includes badge["class"], "badge-primary"
    style = badge["style"].to_s
    refute_includes style, "background-color"
    refute_includes style, "--badge-primary"
    refute_includes style, absent
    refute_includes badge.to_html, absent
    frame = badge.ancestors.find { |node| node["data-cover-frame"] }
    assert frame, "expected the badge inside the cover frame"
    assert_includes frame["class"], "fp-overlay"
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      actor: @user,
      title: title
    )
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-cover", status: "published" }
    )
    raise result.error if result.failure?

    kit.reload
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

  def install_center(brand_color:, font_family:)
    remove_press_centers
    center = Struct.new(:brand_color, :font_family).new(brand_color, font_family)
    mod = Module.new
    mod.define_singleton_method(:branding_for) { |_recording| center }
    Object.const_set(:RecordingStudioPressCenters, mod)
  end

  def remove_press_centers
    return unless defined?(RecordingStudioPressCenters)

    Object.send(:remove_const, :RecordingStudioPressCenters)
  end
end
