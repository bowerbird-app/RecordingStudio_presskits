# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class TextSectionPresentationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "text-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Text Section #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "the text component collapses only long copy" do
    short = component_for("<p>Short note.</p>")
    designed = component_for(designed_blurb)
    edge = component_for("<p>#{'a' * RecordingStudioPresskits::Text::Component::COLLAPSE_AFTER}</p>")
    long = component_for("<p>#{'a' * (RecordingStudioPresskits::Text::Component::COLLAPSE_AFTER + 1)}</p>")
    blank = component_for("<p>  </p>")

    refute short.collapsible?
    refute designed.collapsible?
    refute edge.collapsible?
    assert long.collapsible?
    assert long.render?
    refute blank.render?
    assert_equal 8, RecordingStudioPresskits::Text::Component::VISIBLE_LINES
  end

  test "public text uses the theme body and a heading slot, and only long copy collapses" do
    kit = record_kit("Summer launch")
    section = record_text(kit, "About the collection")
    revise_body(section, designed_blurb)
    record_images(kit)
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_blank_public_layout

    text = css_select("[data-presskits-text-section]").first
    assert text
    assert_includes text["class"], "gap-7"
    assert_includes text["class"], "pt-8"
    card = css_select("[data-presskits-text-section]").first.parent
    assert_equal "true", card["data-section-card"]
    assert_includes card["class"], "rounded-[var(--radius-lg)]"
    heading = css_select("[data-presskits-text-section] h2").first
    assert_equal "About the collection", heading.text
    assert_includes heading["class"], "font-bold"
    assert_includes heading["class"], "text-[2rem]"
    assert_includes heading["class"], "text-[var(--surface-content-color)]"
    assert_select "[data-presskits-text-section] [data-presskits-text-copy-slot]", count: 1
    refute_includes text.to_html, "Copy text"
    body = css_select("[data-presskits-text-body]").first
    assert_includes body["class"], "text-base"
    assert_includes body["class"], "leading-7"
    assert_includes body["class"], "max-w-[65ch]"
    assert_includes body["class"], "text-[var(--surface-muted-content-color)]"
    assert_includes body["class"], "[&_p+p]:mt-5"
    assert_includes body.text, "mouth-blown"
    refute_includes body["class"], "max-h-[14rem]"
    refute_select "[data-presskits-text-collapse]"
    refute_select "button", text: /Show more/
    refute_includes text.to_html, "ProseMirror"
    refute_includes text.to_html, "flat-pack-richtext"
    assert_select "[data-presskits-text-copy-slot]", count: 1
    refute_select ".fp-section-title", text: /Press photos/

    content = section_content(section)
    @root.revise(content) { |text_record| text_record.body = long_body }
    get kit.publishable_public_path
    assert_response :success
    collapsed = css_select("[data-presskits-text-body]").first
    assert_includes collapsed["class"], "max-h-[14rem]"
    assert_includes collapsed["class"], "overflow-hidden"
    assert_includes collapsed["class"], "text-[var(--surface-muted-content-color)]"
    assert_includes collapsed.text, "Last line of the notes"
    assert_select "[data-controller='recording-studio-presskits--text-collapse']"
    assert_select "[data-presskits-text-collapse] [class*='from-[var(--card-background-color)]']"
    toggle = css_select("[data-presskits-text-collapse] button").first
    assert_equal "false", toggle["aria-expanded"]
    assert_equal collapsed["id"], toggle["aria-controls"]
    assert_equal "default", toggle["data-fp-style"]
    assert_includes toggle["class"], "fp-button"
    assert_includes toggle["class"], "fp-button-raised"
    refute_includes toggle["class"], "fp-button-flat"
    assert_includes toggle.to_html, "Show more"
    refute_includes toggle.to_html, "Show less"
    assert_includes toggle["data-action"], "recording-studio-presskits--text-collapse#toggle"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success
    assert_select "[data-presskits-text-section] h2", text: "About the collection"
    assert_select "[data-presskits-text-body].max-h-\\[14rem\\]"
    assert_select "[data-presskits-text-collapse] button[aria-expanded='false']"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    editor = css_select("#presskits-section-#{section.id}").first
    assert_includes editor.text, "Last line of the notes"
    refute_includes editor.to_html, "recording-studio-presskits--text-collapse"
    refute_includes editor.to_html, "Show more"
    assert_select "#presskits-section-#{section.id} [data-flat-pack--inline-edit-mode-value='rich']"
    assert_select "#presskits-section-#{section.id} .flat-pack-richtext-bubble-menu"
    editor_title = css_select("#presskits-section-#{section.id} .fp-inline-edit--text h2").first
    assert_includes editor_title["class"], "font-bold"
    assert_includes editor_title["class"], "text-[2rem]"
    image = content_section(kit, RecordingStudioPresskits::Images)
    image_title = css_select("#presskits-section-#{image.id} .fp-inline-edit--text h2").first
    assert_includes image_title["class"], "text-2xl"
    assert_includes image_title["class"], "font-semibold"
    refute_select "#presskits-section-#{image.id} [data-presskits-text-copy-slot]"
    refute_select "#presskits-section-#{image.id} [data-presskits-text-collapse]"
  end

  private

  def component_for(html)
    recording = Struct.new(:id, :recordable).new("text-1", Struct.new(:body).new(html))
    RecordingStudioPresskits::Text::Component.new(recording: recording)
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_text(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: title
    )
  end

  def record_images(kit)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Images",
      actor: @user,
      title: "Press photos"
    )
  end

  def revise_body(section, html)
    @root.revise(section_content(section)) { |text| text.body = html }
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def content_section(kit, klass)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(klass)
    end
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "text-section-#{SecureRandom.hex(4)}", status: "published" }
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

  def designed_blurb
    [
      "<p>Aura’s Summer 2026 collection brings the warmth of late afternoon light indoors — a family of sculptural pendant, wall and table lamps made to soften the edges of everyday living.</p>",
      "<p>Each globe is mouth-blown by a small studio of glassmakers and finished by hand, so no two pieces are quite alike. The matte, slightly translucent surface diffuses light into a low, honeyed glow that shifts through the day.</p>",
      "<p>The collection launches on 12 October 2026 in five colourways — Sun, Clay, Sage, Mist and Ink — through Aura stores and online in Australia, New Zealand and the UK, from AUD $420.</p>"
    ].join
  end

  def long_body
    paragraphs = Array.new(6) do |index|
      "<p>#{'Notes about the collection and the people who made it. ' * 8}Paragraph #{index + 1}.</p>"
    end
    paragraphs << "<p>Last line of the notes.</p>"
    paragraphs.join
  end
end
