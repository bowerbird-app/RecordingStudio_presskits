# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class KitEditorPreviewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "preview-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Preview Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "kit editor is a full-width preview with a slim toolbar" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_select "#presskits-editor-toolbar"
    assert_select "#presskits-editor-preview"
    assert_select "#pk-editor"
    assert_select "#pk-editor-screen"
    refute_select "#presskits-editor-dialog"
    refute_includes response.body, "md:grid-cols-2"
    refute_select "#presskits-editor-grid"
    refute_select "#presskits-editor-actions"
    assert_select "#presskits-section-picker", text: "Section"
    assert_select "#presskits-editor-toolbar", text: /Order/
    assert_select "#presskits-visibility", text: "Visibility"
    assert_select "#presskits-visibility [data-flat-pack--icon-name-value='eye']"
    assert_select "#presskits-downloads", text: "Downloads"
    assert_select "#presskits-downloads [data-flat-pack--icon-name-value='arrow-down-tray']"
    assert_select "#embargo_button_#{kit.id}", text: "+ Embargo"
    refute_select "#presskits-editor-toolbar a", text: "Header"
    refute_select "#presskits-editor-toolbar a", text: "View"
    header = css_select("#presskits-kit-header").first
    assert_includes header["class"], "after:inset-0"
    assert_includes header["class"], "hover:after:bg-[color-mix(in_oklab,black_16%,transparent)]"
    refute_includes header["class"], "pt-8"
    refute_includes header["class"], "hover:bg-[var(--surface-muted-background-color)]"
    refute_includes header["class"], "-m-4"
    refute_includes header["class"], "pr-20"
    preview = css_select("#presskits-editor-preview").first
    assert_includes preview["class"], "gap-6"
    refute_includes preview["class"], "overflow-hidden"
    refute_includes preview["class"], "md:p-4"
    refute_includes preview["class"], "lg:p-6"
    assert_select "#presskits-editor-sections [data-section-card]"
    refute_select "#presskits-cover-hero"
    card = css_select("#presskits-kit-header [data-cover-card]").first
    assert_includes card["class"], "@container"
    assert_includes card["class"], "w-full"
    assert_select "#presskits-kit-header [data-cover-tag]", text: "Press kit"
    assert_select "#presskits-kit-header [data-cover-title]", text: "Spring launch"
    refute_includes card.to_html, "aspect-[1440/640]"
    refute_includes card.to_html, "fp-display"
    cover = css_select("#presskits-kit-cover").first
    assert_includes cover["class"], "w-full"
    assert_includes cover["class"], "h-full"
    title = css_select("#presskits-kit-cover [data-cover-title] h1").first
    assert_equal "h1", title.name
    frame = css_select("#presskits-kit-cover [data-cover-frame]").first
    assert_includes frame["class"], "aspect-[430/368]"
    assert_select "#presskits-kit-cover [data-cover-eyebrow]", text: "Press kit"
    assert_select "#presskits-kit-cover [data-cover-fallback]"
    sections = css_select("#presskits-editor-sections").first
    assert_includes sections["class"], "flex"
    assert_includes sections["class"], "gap-6"
    refute_includes sections["class"], "p-5"
    refute_includes sections["class"], "md:p-8"
    refute_includes sections["class"], "lg:p-10"
    refute_select "#presskits-kit-header .fp-fab"
    header_actions = css_select("#presskits-kit-header [data-presskits-header-actions]").first
    assert_includes header_actions["class"], "max-sm:opacity-100"
    assert_includes header_actions["class"], "self-end"
    assert_includes header_actions["class"], "[@media(hover:none)]:opacity-100"
    assert_includes header_actions["class"], "[@media(hover:hover)]:group-hover/pk-edit:opacity-100"
    assert_includes header_actions.parent["class"], "flex-col-reverse"
    assert_includes header_actions.parent["class"], "sm:justify-between"
    edit = css_select("#presskits-kit-header [data-presskits-header-actions] a[aria-label='Edit']").first
    assert_includes edit["class"], "px-[var(--button-padding-x-sm)]"
    assert_includes edit["class"], "text-xs"
    assert_includes edit["class"], "max-sm:[&>span]:sr-only"
    image_actions = css_select("#presskits-kit-header [data-presskits-header-image-actions]").first
    assert_includes image_actions["class"], "[@media(hover:none)]:opacity-100"
    refute_includes image_actions["class"], "self-end"
    assert_equal "top_right", image_actions.parent["data-fp-placement"]
    assert_equal "md", image_actions.parent["data-fp-inset"]
    assert_select "h1", text: "Spring launch"
    assert_select "#presskits-toasts"
    assert_select "#presskits-sections-modal"
    assert_select "#presskits-section-picker-modal"
    header_card = css_select("#presskits-kit-header [data-cover-card]").first
    assert_includes header_card["class"], "rounded-[var(--radius-lg)]"
    assert_includes header_card["class"], "bg-[var(--card-background-color)]"
    empty_card = css_select("#presskits-editor-sections [data-section-card]").first
    assert_includes empty_card["class"], "rounded-[var(--radius-lg)]"
    assert_includes empty_card["class"], "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
    editor = css_select("[data-controller='recording-studio-presskits--editor-chrome']").first
    assert editor
    assert_includes editor["data-action"], "onPointerDown"
    assert_select "#presskits-kit-header [data-presskits-header-actions] [data-flat-pack--icon-name-value='pencil']"
    assert_select "#presskits-kit-header [data-presskits-header-image-actions] [data-flat-pack--icon-name-value='photo']"
  end

  test "each section has heading and content controls" do
    kit = record_kit("Spring launch")
    section = record_text(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    remove = recording_studio_presskits.press_kit_section_path(kit, section)
    body = css_select("#presskits-section-#{section.id}-body").first
    refute_includes body["class"], "hover:bg-[var(--surface-muted-background-color)]"
    refute_includes body["class"], "[@media(hover:hover)]"
    assert_includes body["class"], "data-[pk-edit-active]"
    refute_includes body["class"], "[@media(hover:none)]:opacity-100"
    assert_includes body["class"], "focus-visible:outline"
    assert_includes body["class"], "relative"
    assert_includes body["class"], "pt-8"
    assert_includes body["class"], "md:pt-10"
    assert_includes body["class"], "lg:pt-12"
    refute_includes body["class"], "pr-20"
    refute_includes body["class"], "-m-4"
    assert_includes body["class"], "rounded-[var(--radius-lg)]"
    section_card = css_select("#presskits-section-#{section.id} [data-section-card]").first
    assert_includes section_card["class"], "shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]"
    assert_includes section_card["class"], "bg-[var(--card-background-color)]"
    refute_includes body["class"], "hover:outline-[var(--color-primary)]"
    refute_select "#presskits-section-#{section.id} .fp-fab"
    refute_select "#presskits-section-picker-after-#{section.id}"
    refute_select "#presskits-section-#{section.id} [data-turbo-confirm]"
    actions = css_select("#presskits-section-#{section.id}-actions").first
    assert_includes actions["class"], "max-sm:opacity-100"
    assert_includes actions["class"], "self-end"
    assert_includes actions["class"], "sm:self-auto"
    assert_includes actions["class"], "[@media(hover:none)]:opacity-100"
    assert_includes actions["class"], "[@media(hover:hover)]:group-hover/pk-edit:opacity-100"
    assert_includes actions.parent["class"], "flex-col-reverse"
    assert_includes actions.parent["class"], "sm:flex-row"
    assert_includes css_select("#presskits-section-#{section.id} .fp-section-title").first["class"], "max-sm:mt-0"
    text_actions = css_select("#presskits-section-#{section.id}-actions").first.to_html
    assert_operator text_actions.index(">Order<"), :<, text_actions.index("fp-trash-button")
    assert_select "#presskits-section-#{section.id} .fp-trash-button[data-fp-size='sm'][style*='--hit-target-min: 0px']"
    assert_select "#presskits-section-#{section.id}-actions a[href='##{section.id}']", text: "Order"
    assert_select "#presskits-section-#{section.id}-actions a[data-modal-id='presskits-sections-modal']", text: "Order"
    order_link = css_select("#presskits-section-#{section.id}-actions a[href='##{section.id}']").first
    assert_equal "Order", order_link["aria-label"]
    assert_includes order_link["class"], "max-sm:[&>span]:sr-only"
    assert_includes order_link["class"], "max-sm:px-[var(--button-icon-only-padding-sm)]"
    refute_includes order_link["class"], "fp-hit-target"
    assert_select "#presskits-section-#{section.id}-actions a span", text: "Order"
    refute_select "#presskits-section-#{section.id}-actions a", text: "Edit"
    assert_select "#presskits-section-#{section.id} .fp-trash-button form[action='#{remove}']"
    assert_select "#presskits-section-#{section.id} .fp-trash-button input[name='_method'][value='delete']"
    assert_select "#presskits-section-#{section.id} .fp-inline-edit input[name='kit_section[title]']"
    assert_select "#presskits-section-#{section.id} [data-placeholder='Add a subtitle']"
    assert_select "#presskits-section-#{section.id} [data-flat-pack--inline-edit-mode-value='rich']"
    assert_select "#presskits-section-#{section.id} .flat-pack-richtext-bubble-menu"
    assert_select "#presskits-section-#{section.id} input[name='text[body]']"
    title = css_select("#presskits-section-#{section.id} .fp-inline-edit--text h2").first
    assert title
    assert_includes title["class"], "text-2xl"
    title_edit = css_select("#presskits-section-#{section.id} .fp-inline-edit").find { |node| node.at_css("h2") }
    assert_equal remove, title_edit["data-flat-pack--inline-edit-update-url-value"]

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    images = content_section(kit, RecordingStudioPresskits::Images)
    follow_redirect!
    image_actions = css_select("#presskits-section-#{images.id}-actions").first.to_html
    assert_operator image_actions.index(">Edit<"), :<, image_actions.index(">Order<")
    assert_operator image_actions.index(">Order<"), :<, image_actions.index("fp-trash-button")
    assert_select "#presskits-section-#{images.id}-actions a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, images)}']",
                  text: "Edit"
    assert_select "#presskits-section-#{images.id}-actions a[data-modal-id='pk-editor'][data-turbo-frame='pk-editor-screen']",
                  text: "Edit"
    edit_link = css_select("#presskits-section-#{images.id}-actions a[data-modal-id='pk-editor']").first
    assert_equal "Edit", edit_link["aria-label"]
    assert_includes edit_link["class"], "max-sm:[&>span]:sr-only"
    refute_includes edit_link["class"], "fp-hit-target"
    refute_select "#presskits-section-#{images.id} [data-flat-pack--inline-edit-mode-value='rich']"
  end

  test "adding a section saves the type title and returns to the kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::StatsSection" }
    section = content_section(kit, RecordingStudioPresskits::StatsSection)
    assert_equal "Stats", section.recordable.title
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit, highlight: section.id)
    follow_redirect!
    assert_response :success
    assert_select "#presskits-section-#{section.id}"
    assert_select "#presskits-section-placeholder", text: /Add a stat/
    assert_select ".fp-section-title h2", text: "Stats"
  end

  test "empty sections stay off the public kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    follow_redirect!
    assert_select "#presskits-section-placeholder"

    publish_kit!(kit)
    get kit.publishable_public_path
    assert_response :success
    refute_select ".fp-section-title"
    refute_includes response.body, "Edit heading"
  end

  test "heading editor is shared and content editor omits title fields" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    section = content_section(kit, RecordingStudioPresskits::Text)
    follow_redirect!

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "input[name='kit_section[title]']"
    assert_select "input[name='kit_section[subtitle]']"
    refute_select "input[type=hidden][name='text[body]']"
    refute_select "#presskits-section-tabs"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "label", text: "Body"
    refute_select "input[name='kit_section[title]']"
    refute_select "#presskits-section-preview"
    refute_select "#presskits-section-tabs"
  end

  test "a title save leaves the subtitle when the request omits it" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    section = content_section(kit, RecordingStudioPresskits::Images)
    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Press photos", subtitle: "Doors at noon" }
    }
    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Night photos" }
    }
    section.reload
    assert_equal "Night photos", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { subtitle: "Bring a coat" }
    }
    section.reload
    assert_equal "Night photos", section.recordable.title
    assert_equal "Bring a coat", section.recordable.subtitle
  end

  test "heading save stays on the heading and updates the stored title" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    section = content_section(kit, RecordingStudioPresskits::Images)

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Press photos", subtitle: "Doors at noon" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)
    follow_redirect!
    assert_equal "Press photos", section.reload.recordable.title
    assert_select "input[name='kit_section[title]'][value='Press photos']"
  end

  test "heading and content screens wrap in the navigable modal frame" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::StatsSection" }
    section = content_section(kit, RecordingStudioPresskits::StatsSection)

    get recording_studio_presskits.heading_press_kit_section_path(kit, section),
        headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_select "turbo-frame#pk-editor-screen"
    assert_select "[data-fp-screen][data-title='Section heading']"
    assert_select "input[name='kit_section[title]']"
    assert_select "form#presskits-section-title-form[data-turbo-frame='_top']"
    refute_select ".fp-page-title"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section),
        headers: { "Turbo-Frame" => "pk-editor-screen" }
    assert_response :success
    assert_select "turbo-frame#pk-editor-screen"
    assert_select "a[data-fp-nav='push']", text: "Stat"
    assert_select "form#presskits-stats-columns-form[data-turbo-frame='_top']"
    refute_select "[name='stats_section[display_style]']"
  end

  test "stat turbo stream updates the preview and leaves the modal" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::StatsSection" }
    section = content_section(kit, RecordingStudioPresskits::StatsSection)
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    stat = content.record(RecordingStudioPresskits::Stat, parent_recording: content, actor: @user) do |recordable|
      recordable.label = "Projects"
      recordable.value = "120"
    end

    patch recording_studio_presskits.press_kit_section_stat_path(kit, section, stat),
          params: {
            stat: { label: "Projects", value: "121" },
            from_kit_editor: "1"
          },
          as: :turbo_stream
    assert_response :success
    assert_equal "121", stat.reload.recordable.value
    assert_includes response.body, "presskits-section-#{section.id}"
    assert_includes response.body, "121"
    refute_includes response.body, "turbo-stream action=\"update\" target=\"pk-editor\""
  end

  test "heading turbo stream updates the preview and leaves the modal" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    section = content_section(kit, RecordingStudioPresskits::Text)

    patch recording_studio_presskits.press_kit_section_path(kit, section),
          params: {
            kit_section: { title: "Press photos", subtitle: "Doors at noon" },
            from_kit_editor: "1"
          },
          as: :turbo_stream
    assert_response :success
    assert_includes response.body, "presskits-section-#{section.id}"
    assert_includes response.body, "Press photos"
    refute_includes response.body, "presskits-editor-dialog"
    refute_includes response.body, 'turbo-stream action="update" target="pk-editor"'
  end

  test "turbo stream create inserts the section and offers undo" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images", from_kit_editor: "1" },
         as: :turbo_stream
    section = content_section(kit, RecordingStudioPresskits::Images)
    assert_response :success
    assert_includes response.body, "presskits-section-#{section.id}"
    assert_includes response.body, I18n.t("recording_studio_presskits.editor.undo")
    assert_includes response.body, "turbo-stream"
  end

  test "adding after a section uses orderable" do
    kit = record_kit("Spring launch")
    first = record_text(kit)
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit), params: {
      type: "RecordingStudioPresskits::QuoteSection",
      after_recording_id: first.id
    }
    second = content_section(kit, RecordingStudioPresskits::QuoteSection)
    assert_equal [first.id, second.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)

    third = record_block(kit, "Notes")
    post recording_studio_presskits.press_kit_sections_path(kit), params: {
      type: "RecordingStudioPresskits::StatsSection",
      after_recording_id: first.id
    }
    inserted = content_section(kit, RecordingStudioPresskits::StatsSection)
    assert_equal [first.id, inserted.id, second.id, third.id],
                 RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
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

  def record_text(kit)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user
    )
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      title: title,
      actor: @user
    )
  end

  def content_section(kit, klass)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      RecordingStudioPresskits::KitQuery.section_content(section)&.recordable.is_a?(klass)
    end
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-preview", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    kit.reload
  end
end
