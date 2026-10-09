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
    Current.actor = @previous_actor
    RecordingStudioPresskits.configuration.cover_colors = RecordingStudioPresskits::Cover::Palette::DEFAULT_COLORS.dup
    RecordingStudioPresskits.configuration.default_cover_color = RecordingStudioPresskits::Cover::Palette::DEFAULT_COLOR
    RecordingStudioPresskits.configuration.cover_text_colors = RecordingStudioPresskits::Cover::Palette::DEFAULT_TEXT_COLORS.dup
    RecordingStudioPresskits.configuration.cover_text_auto = true
  end

  test "nil cover style and colour render as the default colour cover" do
    kit = record_kit("Spring launch")

    assert_nil kit.recordable.cover_style
    assert_nil kit.recordable.cover_color
    assert_equal "color", kit.recordable.resolved_cover_style
    assert_equal "#1F2937", kit.recordable.resolved_cover_color
    assert_equal "#F8FAFC", kit.recordable.overlay_text_color
    assert_nil kit.recordable.cover_text_color
    assert_equal "#F8FAFC", kit.recordable.resolved_cover_text_color
  end

  test "cover colour must be hex and in the palette when the colour changes" do
    kit = record_kit("Spring launch")

    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.cover_color = "blue" }
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.cover_color = "#FFFFFF" }
    end

    @root.revise(kit) { |press_kit| press_kit.cover_color = "#7c3aed" }
    assert_equal "#7C3AED", kit.reload.recordable.cover_color

    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.cover_style = "media" }
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      @root.revise(kit) { |press_kit| press_kit.cover_text_color = "white" }
    end

    @root.revise(kit) { |press_kit| press_kit.cover_text_color = "#f8fafc" }
    assert_equal "#F8FAFC", kit.reload.recordable.cover_text_color
    assert_equal "#F8FAFC", kit.recordable.resolved_cover_text_color
  end

  test "a stored colour stays after the host drops it from the palette" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.cover_color = "#DB2777" }
    kit.reload
    RecordingStudioPresskits.configuration.cover_colors = %w[#1F2937 #7C3AED]

    @root.revise(kit) { |press_kit| press_kit.description = "Still rose." }
    kit.reload

    assert_equal "#DB2777", kit.recordable.cover_color
    assert_equal "#DB2777", kit.recordable.resolved_cover_color

    @root.revise(kit) { |press_kit| press_kit.cover_text_color = "#111827" }
    kit.reload
    RecordingStudioPresskits.configuration.cover_text_colors = %w[#F8FAFC #E5E7EB]
    @root.revise(kit) { |press_kit| press_kit.description = "Still ink text." }
    kit.reload

    assert_equal "#111827", kit.recordable.cover_text_color
    assert_equal "#111827", kit.recordable.resolved_cover_text_color

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-color='#DB2777']", count: 1
    assert_includes css_select("[data-cover-color='#DB2777']").first.to_html, "Spring launch"
  end

  test "any colour mode accepts a hex that is not on the default palette" do
    RecordingStudioPresskits.configuration.cover_colors = :any
    kit = record_kit("Spring launch")

    @root.revise(kit) { |press_kit| press_kit.cover_color = "#ABCDEF" }
    assert_equal "#ABCDEF", kit.reload.recordable.cover_color

    RecordingStudioPresskits.configuration.cover_text_colors = :any
    @root.revise(kit) { |press_kit| press_kit.cover_text_color = "#010101" }
    assert_equal "#010101", kit.reload.recordable.cover_text_color
  end

  test "header editor shows colour swatch radios and a live preview card" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "input[type=radio][name='press_kit[cover_color]']", count: 5
    assert_select "input[type=radio][name='press_kit[cover_color]'][value='#1F2937'][checked]"
    assert_select "input[type=radio][name='press_kit[cover_text_color]'][value='auto'][checked]"
    assert_select "input[type=radio][name='press_kit[cover_text_color]'][value='#F8FAFC']"
    assert_select ".flat-pack-radio-swatch", minimum: 9
    assert_select ".flat-pack-radio-swatch input[value='auto']", count: 0
    assert_includes response.body, "Ink"
    assert_includes response.body, "Honey"
    assert_includes response.body, "Text colour"
    assert_includes response.body, "Auto"
    assert_includes response.body, "Snow"
    refute_includes response.body, "flat-pack-color-swatch"
    refute_includes response.body, "flat-pack--color-swatch"
    assert_select "#presskits-header-edit-preview h1", text: "Spring launch"
    assert_select "#presskits-header-edit-preview [data-cover-ratio='9 / 16']"
    assert_select "#presskits-header-edit-preview [data-recording-studio-presskits--cover-preview-target=surface]"
    assert_includes response.body, "recording-studio-presskits--cover-preview"
  end

  test "header editor uses a colour swatch when the host allows any colour" do
    RecordingStudioPresskits.configuration.cover_colors = :any
    RecordingStudioPresskits.configuration.cover_text_colors = :any
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.cover_color = "#ABCDEF" }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "input[type=color][name='press_kit[cover_color]'][value='#ABCDEF']"
    assert_select "input[type=radio][name='press_kit[cover_color]']", count: 0
    assert_includes response.body, "flat-pack--color-swatch"
    assert_includes response.body, "Colour"
    assert_includes response.body, "Text colour"
    assert_select "input[type=radio][name='press_kit[cover_text_color]'][value='auto']"
    assert_select "input[type=color][name='press_kit[cover_text_swatch]']"
  end

  test "header save refuses a colour that is not on the palette" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch", cover_style: "color", cover_color: "#FFFFFF" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Pick a colour we can actually paint."
    assert_nil kit.reload.recordable.cover_color

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch", cover_style: "color", cover_color: "#1F2937", cover_text_color: "#FFFFFF" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Pick a text colour we can actually paint."
    assert_nil kit.reload.recordable.cover_text_color
  end

  test "header save stores a text colour and auto clears it" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch",
        cover_style: "color",
        cover_color: "#1F2937",
        cover_text_color: "#E5E7EB"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_equal "#E5E7EB", kit.reload.recordable.cover_text_color
    refute kit.recordable.cover_text_low_contrast?

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch",
        cover_style: "color",
        cover_color: "#1F2937",
        cover_text_color: "auto"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_nil kit.reload.recordable.cover_text_color
    assert_equal "#F8FAFC", kit.recordable.resolved_cover_text_color
  end

  test "header save keeps a low-contrast text colour" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch",
        cover_style: "color",
        cover_color: "#D97706",
        cover_text_color: "#E5E7EB"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_equal "#E5E7EB", kit.reload.recordable.cover_text_color
    assert kit.recordable.cover_text_low_contrast?

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_includes response.body, "That text may be hard to read on this colour."
  end

  test "public kit and owner preview use the hero cover" do
    kit = record_kit("Spring launch")
    @root.revise(kit) do |press_kit|
      press_kit.description = "Doors at noon."
      press_kit.cover_color = "#059669"
      press_kit.cover_text_color = "#111827"
    end
    record_block(kit, "Hero")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-cover-hero h1", text: "Spring launch"
    assert_select "#presskits-cover-hero[data-cover-color='#059669']"
    assert_select "#presskits-cover-hero[data-cover-text-color='#111827']"
    assert_select "#presskits-cover-hero[data-cover-ratio='21 / 9']"
    assert_includes response.body, "Doors at noon."
    public_preview = css_select("#presskits-public-preview").first
    assert_includes public_preview["class"], "overflow-hidden"
    assert_includes public_preview["class"], "rounded-[var(--radius-lg)]"
    public_hero = css_select("#presskits-cover-hero").first
    assert_includes public_hero["class"], "rounded-none"
    assert_includes public_hero["class"], "p-8"
    assert_includes public_hero["class"], "md:p-12"
    public_sections = css_select("#presskits-public-sections").first
    refute_includes public_sections["class"], "gap-6"
    refute_includes public_sections["class"], "p-5"
    section_pad = css_select("#presskits-public-sections > div").first
    assert_includes section_pad["class"], "pt-8"
    assert_includes section_pad["class"], "md:pt-10"
    assert_includes section_pad["class"], "lg:pt-12"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-cover-hero h1", text: "Spring launch"
    assert_select "#presskits-cover-hero[data-cover-color='#059669']"
    assert_select "#presskits-cover-hero[data-cover-text-color='#111827']"
    assert_select "#presskits-cover-hero[data-cover-ratio='21 / 9']"
    preview = css_select("#presskits-public-preview").first
    assert_includes preview["class"], "overflow-hidden"
    assert_includes preview["class"], "rounded-[var(--radius-lg)]"
  end

  test "press kit payload reads resolved cover fields" do
    kit = record_kit("Spring launch")

    assert_equal(
      { title: "Spring launch", description: nil, cover_style: "color", cover_color: "#1F2937", cover_text_color: "#F8FAFC" },
      RecordingStudioPresskits::Api::PressKitPayload.for(kit.recordable)
    )

    @root.revise(kit) do |press_kit|
      press_kit.description = "Doors at noon."
      press_kit.cover_style = "color"
      press_kit.cover_color = "#7C3AED"
      press_kit.cover_text_color = "#111827"
    end

    assert_equal(
      {
        title: "Spring launch",
        description: "Doors at noon.",
        cover_style: "color",
        cover_color: "#7C3AED",
        cover_text_color: "#111827"
      },
      RecordingStudioPresskits::Api::PressKitPayload.for(kit.reload.recordable)
    )
  end

  test "grid cards keep a shared 9 by 16 height" do
    first = record_kit("Spring launch")
    second = record_kit("Autumn recap")
    @root.revise(first) { |press_kit| press_kit.cover_color = "#7C3AED" }
    @root.revise(second) do |press_kit|
      press_kit.description = "A longer line that should clamp on the card."
      press_kit.cover_color = "#D97706"
    end
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-color='#7C3AED']", count: 1
    assert_select "[data-cover-color='#D97706']", count: 1
    assert_select "[data-cover-text-color='#F8FAFC']", count: 1
    assert_select "[data-cover-text-color='#111827']", count: 1
    assert_select "[data-cover-ratio='9 / 16']", count: 2
    assert_includes css_select("[data-cover-color='#7C3AED']").first.to_html, "--page-title-h1-size"
  end

  private

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
end
