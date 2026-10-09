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
    refute_select "#presskits-editor-toolbar a", text: "Header"
    refute_select "#presskits-editor-toolbar a", text: "View"
    assert_select "#presskits-kit-header .fp-fab.fp-fab--contained[data-fp-position='top_right'][data-fp-size='sm']"
    assert_select "#presskits-kit-header button.fp-fab__trigger[aria-label='Header actions']"
    assert_select "#presskits-kit-header [role='menuitem'][aria-label='Edit heading']"
    assert_select "h1", text: "Spring launch"
    assert_select "#presskits-toasts"
    assert_select "#presskits-sections-modal"
    assert_select "#presskits-section-picker-modal"
    preview = css_select("#presskits-editor-preview").first
    assert_includes preview.parent["class"], "rounded-[var(--radius-lg)]"
    assert_includes preview.parent["class"], "bg-[var(--card-background-color)]"
    editor = css_select("[data-controller='recording-studio-presskits--editor-chrome']").first
    assert editor
    assert_includes editor["data-action"], "onPointerDown"
    assert_select "#presskits-kit-header button.fp-fab__trigger [data-flat-pack--icon-name-value='plus']"
  end

  test "each section has heading and content controls" do
    kit = record_kit("Spring launch")
    section = record_text(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    heading = recording_studio_presskits.heading_press_kit_section_path(kit, section)
    content = recording_studio_presskits.edit_press_kit_section_path(kit, section)
    remove = recording_studio_presskits.press_kit_section_path(kit, section)
    body = css_select("#presskits-section-#{section.id}-body").first
    assert_includes body["class"], "hover:bg-[var(--surface-muted-background-color)]"
    assert_includes body["class"], "[@media(hover:hover)]"
    assert_includes body["class"], "data-[pk-edit-active]"
    refute_includes body["class"], "[@media(hover:none)]:opacity-100"
    assert_includes body["class"], "focus-visible:outline"
    assert_includes body["class"], "relative"
    refute_includes body["class"], "p-4"
    refute_includes body["class"], "-mx-4"
    refute_includes body["class"], "hover:outline-[var(--color-primary)]"
    assert_select "#presskits-section-#{section.id} .fp-fab.fp-fab--contained[data-fp-position='top_right'][data-fp-size='sm']"
    assert_select "#presskits-section-#{section.id} button.fp-fab__trigger[aria-label='Section actions']"
    assert_select "#presskits-section-#{section.id} button.fp-fab__trigger [data-flat-pack--icon-name-value='plus']"
    fab = css_select("#presskits-section-#{section.id} .fp-fab").first
    assert_includes fab["class"], "group-data-[pk-edit-active]/pk-edit"
    refute_includes fab["class"], "[@media(hover:none)]:opacity-100"
    refute_select "#presskits-section-#{section.id} .fp-fab__backdrop"
    assert_select "a[href='#{heading}'][role='menuitem'][aria-label='Edit title']"
    assert_select "a[href='#{content}'][role='menuitem'][aria-label='Edit content']"
    assert_select "a[href='##{section.id}'][role='menuitem'][aria-label='Reorder'][data-modal-id='presskits-sections-modal']"
    assert_select "a[href='#{remove}'][role='menuitem'][aria-label='Trash'][data-turbo-method='delete'][data-turbo-confirm][data-fp-style='danger']"
    assert_select "[role='menuitem'][aria-label='Add new section'][data-modal-id='presskits-section-picker-after-#{section.id}']"
    assert_select "a[href='#{heading}'][data-turbo-frame='pk-editor-screen'][data-modal-id='pk-editor']"
    assert_select "a[href='#{content}'][data-turbo-frame='pk-editor-screen'][data-modal-id='pk-editor']"
    assert_select "#presskits-section-picker-after-#{section.id}"
    assert_select "#presskits-section-picker-after-#{section.id} a[href*='after_recording_id=#{section.id}']"
    refute_select "#presskits-section-#{section.id} a", text: "Edit heading"
    refute_select "#presskits-section-dropdown-after-#{section.id}"
    assert_select ".fp-section-title h2"
  end

  test "adding a section saves the type title and returns to the kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::FactsSection" }
    section = content_section(kit, RecordingStudioPresskits::FactsSection)
    assert_equal "Facts & Figures", section.recordable.title
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit, highlight: section.id)
    follow_redirect!
    assert_response :success
    assert_select "#presskits-section-#{section.id}"
    assert_select "#presskits-section-placeholder", text: /Add a figure/
    assert_select ".fp-section-title h2", text: "Facts & Figures"
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
         params: { type: "RecordingStudioPresskits::FactsSection" }
    section = content_section(kit, RecordingStudioPresskits::FactsSection)

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
    assert_select "a[data-fp-nav='push']", text: "Fact"
    assert_select "form#presskits-facts-display-form[data-turbo-frame='_top']"
  end

  test "fact turbo stream updates the preview and leaves the modal" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::FactsSection" }
    section = content_section(kit, RecordingStudioPresskits::FactsSection)
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    fact = content.record(RecordingStudioPresskits::Fact, parent_recording: content, actor: @user) do |recordable|
      recordable.label = "Projects"
      recordable.value = "120"
    end

    patch recording_studio_presskits.press_kit_section_fact_path(kit, section, fact),
          params: {
            fact: { label: "Projects", value: "121" },
            from_kit_editor: "1"
          },
          as: :turbo_stream
    assert_response :success
    assert_equal "121", fact.reload.recordable.value
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
      type: "RecordingStudioPresskits::FactsSection",
      after_recording_id: first.id
    }
    inserted = content_section(kit, RecordingStudioPresskits::FactsSection)
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
