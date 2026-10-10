# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitUiTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "ui-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "UI Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "root redirects to the mounted press kit index" do
    sign_in @user
    switch_to_root(@root)

    get "/"
    assert_redirected_to "/recording_studio_presskits"
    follow_redirect!

    assert_response :success
    assert_rounded_default_layout
    assert_select "h1", text: "My presskits"
    assert_select "title", text: "My presskits"
    assert_page_nav_without_access
    refute_includes response.body, "Dummy host"
  end

  test "index cards and table show the same kits" do
    kit = record_kit("Spring launch")
    edit_href = recording_studio_presskits.edit_press_kit_path(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_select "a[href='#{edit_href}']"
    assert_presskit_create_button
    assert_library_sidebar
    assert_match(/Presskit.*squares-2x2.*table-cells/m, response.body)
    assert_select "[data-cover-color='#1F2937']", count: 1
    assert_includes response.body, "aspect-[9/16]"
    refute_includes response.body, "data-flat-pack--icon-name-value='photo'"
    assert_select "a[aria-label='Cards'] [data-flat-pack--icon-name-value='squares-2x2']", count: 1
    assert_select "a[aria-label='Table'] [data-flat-pack--icon-name-value='table-cells']", count: 1
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
    assert_page_nav_close
    assert_layout_back_button(label: "Go back")
    assert_page_nav_without_access

    get recording_studio_presskits.press_kits_path(view: "table")
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_select "a[href='#{edit_href}']", text: "Spring launch"
    assert_includes response.body, "<table"
    assert_presskit_create_button
    assert_library_sidebar
    assert_match(/Presskit.*squares-2x2.*table-cells/m, response.body)
    assert_select "[data-cover-color]", count: 0
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
  end

  test "card view paints the kit colour with the title on top" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.cover_color = "#DB2777" }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-color='#DB2777']", count: 1
    cover = css_select("[data-cover-color='#DB2777']").first
    assert_includes cover.to_html, "Spring launch"
    refute_includes response.body, "https://cdn.example/cover.jpg"
  end

  test "empty index explains what to do next" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_includes response.body, "Nothing here yet"
    assert_includes response.body, "Make a press kit"
    assert_library_sidebar
  end

  test "kit show redirects to the editor" do
    kit = record_kit("Spring launch")
    record_block(kit, "Hero")
    record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kit_path(kit)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    follow_redirect!

    assert_response :success
    assert_rounded_default_layout
    assert_select "#presskits-editor-toolbar span", text: "Section"
    assert_includes response.body, "Hero"
    assert_includes response.body, "Quotes"
    assert_match(/Hero.*Quotes/m, response.body)
    assert_page_nav_close
    assert_layout_back_button(label: "Press kits", href: recording_studio_presskits.press_kits_path)
    assert_access_slot_only
    refute_includes response.body, "Dummy host"
  end

  test "new press kit form renders the PageNav close X" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.new_press_kit_path
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "New press kit"
    assert_page_nav_close
    assert_page_nav_without_access
  end

  test "kit edit shows the kit name and add dropdown without the picker card" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_select "title", text: "Spring launch"
    assert_select "h1", text: "Spring launch"
    refute_select "#presskits-editor-grid"
    refute_includes response.body, "md:grid-cols-2"
    header_path = recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_select "#presskits-kit-header [role='menuitem'][href='#{header_path}'][aria-label='Edit heading']"
    assert_select "#presskits-kit-header [role='menuitem'][aria-label='Cover colours']"
    assert_select "#presskits-kit-header .fp-fab.fp-fab--contained[data-fp-position='top_right'][data-fp-size='sm']"
    refute_select "#presskits-editor-toolbar a[href='#{header_path}']"
    refute_select "#presskits-editor-toolbar a", text: "Header"
    assert_select "#presskits-kit-header input", count: 0
    assert_select "#presskits-kit-header textarea", count: 0
    refute_includes response.body, "0/280 characters"
    refute_select "#presskits-header-row"
    assert_includes response.body, "Spring launch"
    assert_select "#presskits-section-picker", text: "Section"
    assert_select "#presskits-editor-toolbar [data-flat-pack--icon-name-value='plus']", count: 1
    section_button = css_select("#presskits-section-picker").first
    assert_equal "primary", section_button["data-fp-style"]
    assert_includes section_button["class"], "fp-button"
    refute_select "button#presskits-section-picker[disabled]"
    assert_select "#presskits-editor-toolbar", text: /Order/
    assert_select "#presskits-visibility", text: "Visibility"
    assert_select "#presskits-visibility [data-flat-pack--icon-name-value='eye']"
    assert_select "#presskits-downloads", text: "Downloads"
    assert_select "#presskits-downloads [data-flat-pack--icon-name-value='arrow-down-tray']"
    assert_select "#presskits-sections-modal", text: /Reorder/
    assert_select "#presskits-section-picker-list a[href*='type=RecordingStudioPresskits%3A%3AText'] span", text: "Text"
    assert_select "#presskits-section-picker-list a[href*='type=RecordingStudioPresskits%3A%3AText'] span",
                  text: "The story, in your own words."
    assert_section_menu_icon("RecordingStudioPresskits::Text", "document-text")
    assert_section_menu_icon("RecordingStudioPresskits::Images", "photo")
    assert_section_menu_icon("RecordingStudioPresskits::QuoteSection", "chat-bubble-bottom-center-text")
    assert_section_menu_icon("RecordingStudioPresskits::FactsSection", "calculator")
    assert_section_menu_icon("RecordingStudioPresskits::VideoSection", "video-camera")
    toolbar_html = css_select("#presskits-editor-toolbar").to_html
    assert_operator toolbar_html.index("presskits-section-picker"), :<, toolbar_html.index("presskits-visibility")
    assert_operator toolbar_html.index("presskits-visibility"), :<, toolbar_html.index("presskits-downloads")
    assert_operator toolbar_html.index("presskits-downloads"), :<, toolbar_html.index("publishable_quick_actions_")
    refute_includes css_select("#presskits-editor-preview").to_html, 'name="press_kit[title]"'
    refute_includes css_select("#presskits-editor-preview").to_html, 'name="press_kit[description]"'
    assert_select "#presskits-editor-preview #presskits-kit-header"
    refute_includes css_select("#presskits-editor-preview").to_html, "publishable_quick_actions_"
    assert response.body.index('id="presskits-editor-toolbar"') < response.body.index('id="presskits-editor-preview"')
    assert response.body.index('id="presskits-editor-preview"') < response.body.index('id="presskits-kit-header"')
    refute_select "a[href='#{recording_studio_presskits.preview_press_kit_path(kit)}']"
    refute_select "#presskits-editor-toolbar a", text: "View"
    refute_includes response.body, "Pick what to drop into this kit."
    refute_includes response.body, "Fake block"
    assert_select "#publishable_quick_actions_#{kit.id} [role=menu]", count: 1
    assert_access_slot_only
    assert_includes response.body, "publishable_quick_actions_"
    assert_includes response.body, "Draft"
    refute_includes response.body, "EditButtonComponent"
    assert_select "#pk-editor"
    assert_select "#pk-editor-screen"
    refute_select "#presskits-editor-dialog"
    assert_select "#presskits-sections-modal"
    assert_select "#presskits-section-picker-modal"
  end

  test "empty kit editor keeps add and the publish control" do
    kit = record_kit("Empty launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "h1", text: "Empty launch"
    header_path = recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_select "#presskits-kit-header [role='menuitem'][href='#{header_path}'][aria-label='Edit heading']"
    assert_select "#presskits-kit-header input", count: 0
    assert_select "#presskits-kit-header textarea", count: 0
    assert_select "input[name='press_kit[title]']", count: 0
    assert_select "button", text: "Save", count: 0
    assert_includes response.body, "presskits-section-picker"
    empty_section_button = css_select("#presskits-section-picker").first
    assert_equal "primary", empty_section_button["data-fp-style"]
    assert_includes empty_section_button["class"], "fp-button"
    assert_select "#presskits-editor-preview"
    assert_includes response.body, "Nothing to show yet"
    refute_includes response.body, "Fake block"
    assert_select "#publishable_quick_actions_#{kit.id} [role=menu]", count: 1
  end

  test "kit edit links each section and previews both bodies" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    quotes = record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, hero)}'][role='menuitem'][aria-label='Edit content']"
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, quotes)}'][role='menuitem'][aria-label='Edit content']"
    assert_select "a[href='#{recording_studio_presskits.heading_press_kit_section_path(kit, hero)}'][role='menuitem'][aria-label='Edit title']"
    refute_includes response.body, "Fake block: Hero"
    refute_includes response.body, "Fake block: Quotes"
    assert_select "button", text: "Move up", count: 0
    assert_select "button", text: "Move down", count: 0
    shell = css_select("#presskits-section-list").first
    assert_equal "recording-studio-presskits--kit-preview-reload", shell.at_css("[data-controller]")["data-controller"]
    assert_includes shell.to_html, "list:saved->recording-studio-presskits--kit-preview-reload#reload"
    refute_includes shell.to_html, "recording-studio-presskits--section-order"
    refute_select "#presskits-header-row"
    list = css_select("#presskits-section-list [role='list']").first
    assert_equal "flat-pack--list-orderable", list["data-controller"]
    assert_includes list["class"], "flat-pack-list--orderable"
    assert_includes list["class"], "flat-pack-list-divided"
    assert_equal recording_studio_presskits.press_kit_order_path(kit),
                 list["data-flat-pack--list-orderable-orderable-url-value"]
    assert_equal "moving_recording_id", list["data-flat-pack--list-orderable-param-uuid-name-value"]
    assert_equal "target_position", list["data-flat-pack--list-orderable-param-target-position-name-value"]
    items = css_select("#presskits-section-list [role='listitem']")
    assert_equal [hero.id, quotes.id], items.map { |item| item["id"] }
    items.each do |item|
      refute_includes item.to_html, "arrows-up-down"
      assert_includes item["class"], "!items-center"
      assert_includes item.to_html, 'data-flat-pack--icon-name-value="trash"'
      assert_select item, "button[aria-label='Remove']", count: 1
      assert_select item, "input[name='_method'][value='delete']", count: 1
    end
    preview = css_select("#presskits-editor-preview").first
    assert_includes preview.text, "Hero"
    assert_includes preview.text, "Quotes"
    assert_select "#presskits-section-#{hero.id}"
    assert_select "#presskits-section-#{quotes.id}"
    assert response.body.index('id="presskits-kit-header"') < response.body.index('id="presskits-section-list"')
    refute_includes css_select("#presskits-section-list").to_html, "presskits-kit-header"
    refute_includes css_select("#presskits-section-list").to_html, 'name="press_kit[description]"'
  end

  test "section edit shows that section" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_section_path(kit, hero)
    assert_response :success
    assert_select "title", text: "Hero"
    assert_select "h1", text: "Fake block"
    assert_includes response.body, "Hero"
    refute_includes response.body, "Quotes"
    refute_includes response.body, "md:grid-cols-2"
    refute_select "#presskits-section-preview"
    refute_select "input[name='kit_section[title]']"
    assert_page_nav_without_access
    assert_select "button", text: "Remove", count: 0
    assert_select "input[name='_method'][value='delete']", count: 0
  end

  test "adding an allowed section opens that section" do
    kit = record_kit("Spring launch")
    configuration = RecordingStudioPresskits.configuration
    previous = Array(configuration.excluded_picker_types)
    configuration.excluded_picker_types = previous - ["FakeBlock"]
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { FakeBlock.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit), params: { type: "FakeBlock", title: "Hero" }
    end

    hero = RecordingStudioPresskits::KitQuery.sections_for(kit).find { |child| child.recordable.title == "Hero" }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit, highlight: hero.id)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_includes response.body, "Hero"
    assert_select "#presskits-section-#{hero.id}"
    assert_access_slot_only
  ensure
    configuration.excluded_picker_types = previous if defined?(previous) && previous
  end

  test "section update without an editor does not revise" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_section_path(kit, hero), params: {
      fake_block: { title: "Changed" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, hero)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Nothing to save here yet."
    assert_equal "Hero", hero.reload.recordable.title
  end

  test "section update saves the permitted title and drops a decoy" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    editor = Class.new(ViewComponent::Base) do
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      def self.param_key
        :fake_block
      end

      def self.permitted_attributes
        [:title]
      end

      def call
        ""
      end
    end
    Object.const_set(:PresskitsFakeBlockEditor, editor)
    RecordingStudioPresskits.register_section_editor("FakeBlock", editor)
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_section_path(kit, hero), params: {
      fake_block: { title: "", decoy: "nope" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Could not save that section."
    assert_equal "Hero", hero.reload.recordable.title

    patch recording_studio_presskits.press_kit_section_path(kit, hero), params: {
      fake_block: { title: "Hero, revised", decoy: "nope" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, hero)
    follow_redirect!
    assert_response :success
    content = section_content(hero)
    assert_equal "Hero", hero.reload.recordable.title
    assert_equal "Hero, revised", content.recordable.title
    refute_includes content.recordable.attributes.values, "nope"
    refute_includes response.body, "nope"
  ensure
    RecordingStudioPresskits.configuration.section_editors.delete("FakeBlock")
    Object.send(:remove_const, :PresskitsFakeBlockEditor) if Object.const_defined?(:PresskitsFakeBlockEditor, false)
  end

  test "adding a text section saves the body and drops a decoy" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::Text.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::Text" }
    end

    section = content_section(kit, RecordingStudioPresskits::Text)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit, highlight: section.id)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_access_slot_only
    assert_equal "Text", section.recordable.title
    assert_nil section.recordable.subtitle
    assert_equal RecordingStudioPresskits::Text.opening_body, section_content(section).recordable.body
    assert_select ".fp-section-title h2", text: "Text"
    assert_select "h2", text: "Launch notes"
    assert_select "strong", text: "one-sheet"
    assert_select "li", text: "Photos"
    assert_select ".flat-pack-richtext--view-mode"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "label", text: "Title"
    assert_select "label", text: "Subtitle"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Text"
    assert_equal "Text", css_select("input[name='kit_section[title]']").first["value"]
    assert_heading_form_save_button(kit, section)

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "label", text: "Body"
    assert_select "input[type=hidden][name='text[body]'][value=?]", RecordingStudioPresskits::Text.opening_body
    assert_includes response.body, "&quot;preset&quot;:&quot;content&quot;"
    assert_includes response.body, "&quot;toolbar&quot;:&quot;standard&quot;"
    assert_select "h1", text: "Text"
    assert_select "label", text: "Text", count: 0
    refute_select "input[name='kit_section[title]']"
    refute_select "#presskits-section-preview"
    assert_select "button", text: "Upload", count: 0
    assert_select "button", text: "Save", count: 0
    assert_layout_back_button(label: "Back to kit", href: recording_studio_presskits.edit_press_kit_path(kit))
    refute section_editor_cancel?
    content_form = css_select("#presskits-section-content-form").first
    assert_equal "flat-pack--unsaved-changes", content_form["data-controller"]
    content_html = content_form.to_html
    assert_includes content_html, 'name="text[body]"'
    assert_operator content_html.index(">Body<"), :<, content_html.index(">Update<")
    refute_includes content_html, 'name="kit_section[title]"'
    assert_select "button", text: "Remove", count: 0

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      text: { body: "", decoy: "nope" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Could not save that section."
    assert_equal RecordingStudioPresskits::Text.opening_body, section_content(section).reload.recordable.body

    original_section_id = section.recordable_id
    original_text_id = section_content(section).recordable_id
    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Launch notes", subtitle: "Doors at noon", decoy: "nope" },
      text: {
        body: "<h2>Set list</h2><p>Line two</p><script>alert(1)</script>",
        decoy: "nope"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    section.reload
    content = section_content(section)
    refute_equal original_section_id, section.recordable_id
    refute_equal original_text_id, content.recordable_id
    assert_equal "Launch notes", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle
    old_heading = RecordingStudioPresskits::KitSection.find(original_section_id)
    refute_equal "Launch notes", old_heading.title
    assert_includes content.recordable.body, "<h2>Set list</h2>"
    assert_includes content.recordable.body, "<p>Line two</p>"
    refute_match(/<script/i, content.recordable.body)
    refute_includes content.recordable.body, "alert(1)"
    refute_includes section.recordable.attributes.values, "nope"
    refute_includes content.recordable.attributes.values, "nope"
    assert_select "title", text: "Launch notes"
    assert_select "h1", text: "Text"
    assert_select "label", text: "Body"
    refute_select "input[name='kit_section[title]']"
    refute_select "#presskits-section-preview"
    refute_includes response.body, "nope"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]'][value=?]", "Launch notes"
    assert_select "input[name='kit_section[subtitle]'][value=?]", "Doors at noon"
    assert_select "label", text: "Title"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select ".fp-section-title h2", text: "Launch notes"
    assert_select "h2", text: "Set list"
    assert_select "p", text: "Line two"
    assert_select ".flat-pack-richtext--view-mode"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Launch notes tonight", subtitle: "Doors at noon" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)
    follow_redirect!
    section.reload
    assert_equal "Launch notes tonight", section.recordable.title
    assert_includes section_content(section).recordable.body, "<h2>Set list</h2>"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      text: { body: "<h2>Set list</h2><p>Line two</p>" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    section.reload
    assert_equal "Launch notes tonight", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle
    assert_includes section_content(section).recordable.body, "<h2>Set list</h2>"
    refute_includes section_content(section).recordable.body, "Launch notes tonight"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Launch notes", subtitle: "Doors at noon" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    section_link = "#presskits-section-list a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, section)}']"
    assert_select section_link, text: "Launch notes"
    launch_link = css_select(section_link).first
    assert_equal "Launch notes", launch_link["title"]
    assert_includes launch_link["class"], "truncate"
    text_row = css_select("#presskits-section-list [role='listitem']").find { |item| item["id"] == section.id }
    assert_includes text_row.to_html, 'data-flat-pack--icon-name-value="document-text"'
    refute_includes text_row.to_html, "arrows-up-down"
    assert_includes text_row["class"], "!items-center"
    assert_select ".fp-section-title#launch-notes h2", text: "Launch notes"
    assert_select ".fp-section-title#launch-notes" do |titles|
      refute_includes titles.first.parent["class"].to_s, "gap-4"
    end
    assert_select "a[href='#launch-notes'][aria-label='Copy link to Launch notes']"
    assert_select "[data-controller='flat-pack--section-title-anchor']"
    assert_select "h2", text: "Set list"
    assert_select "p", text: "Line two"

    long_title = "Night set at the riverside hall with the full band and one more encore"
    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: long_title, subtitle: "Doors at noon" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    long_link = css_select(section_link).first
    assert_equal long_title, long_link.text
    assert_equal long_title, long_link["title"]
    assert_includes long_link["class"], "block"
    assert_includes long_link["class"], "truncate"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "   ", subtitle: "   " },
      text: { body: section_content(section).recordable.body }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_nil section.reload.recordable.title
    assert_nil section.recordable.subtitle

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    blank_link = css_select(section_link).first
    assert_equal "Text", blank_link.text
    assert_nil blank_link["title"]
    assert_select ".fp-section-title h2", text: "Text"
    assert_select "h2", text: "Set list"
  end

  test "dropdown rejects dummy fake block types" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_no_difference -> { FakeBlock.count } do
      post recording_studio_presskits.press_kit_sections_path(kit), params: { type: "FakeBlock" }
    end

    follow_redirect!
    assert_response :success
    assert_match(/That section isn(?:'|&#39;)t on the list/, response.body)
  end

  test "remove trashes a child through trashable" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "button[aria-label='Remove'] [data-flat-pack--icon-name-value='trash']", count: 1
    assert_select "button", text: "Remove", count: 0

    content = section_content(hero)
    delete recording_studio_presskits.press_kit_section_path(kit, hero)
    follow_redirect!

    assert_response :success
    refute_includes response.body, "Hero"
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id), hero.id
    assert hero.reload.trashed_at.present?
    assert_equal true, hero.trash_root
    assert content.reload.trashed_at.present?
    assert_equal false, content.trash_root
    assert_nil kit.reload.trashed_at
    assert_equal 1, hero.events.where(action: "trashed").count
  end

  test "move down swaps visible sections and leaves a trashed sibling in place" do
    kit = record_kit("Spring launch")
    first = record_block(kit, "Hero")
    hidden = record_block(kit, "Quotes")
    second = record_block(kit, "Notes")
    hidden.recording_studio_trashable_trash!(actor: @user)
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      recording_id: first.id,
      after_recording_id: second.id
    }
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Order saved."
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert hidden.reload.trashed_at.present?
  end

  test "reorder moves children through orderable" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    quotes = record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      ordered_recording_ids: [quotes.id, hero.id]
    }
    follow_redirect!

    assert_response :success
    assert_equal [quotes.id, hero.id], kit.recording_studio_orderable_children.map(&:id)
  end

  test "dragging a section posts moving_recording_id through orderable" do
    kit = record_kit("Spring launch")
    hero = record_block(kit, "Hero")
    quotes = record_block(kit, "Quotes")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit),
          params: { moving_recording_id: quotes.id, target_position: 1 },
          as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["ok"]
    assert_equal [quotes.id, hero.id], kit.recording_studio_orderable_children.map(&:id)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {}, as: :json
    assert_response :unprocessable_entity
    assert_equal false, JSON.parse(response.body)["ok"]
  end

  test "reordering sections leaves the publishable child alone" do
    kit = record_kit("Spring launch")
    first = record_block(kit, "Hero")
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "section-order-#{SecureRandom.hex(4)}", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    second = record_block(kit, "Notes")
    publishable = kit.child_recordings.find do |child|
      child.recordable_type == "RecordingStudioPublishable::Publishable"
    end
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!

    assert_response :success
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal [second.id, first.id], kit.recording_studio_orderable_children.map(&:id)
    refute_includes kit.recording_studio_orderable_children.map(&:id), publishable.id
    assert_equal kit.id, publishable.reload.parent_recording_id
  end

  test "dragging a section before another uses orderable and leaves a trashed sibling" do
    kit = record_kit("Spring launch")
    first = record_block(kit, "Hero")
    hidden = record_block(kit, "Quotes")
    second = record_block(kit, "Notes")
    hidden.recording_studio_trashable_trash!(actor: @user)
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Order saved."
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal [second.id, first.id, hidden.id], kit.recording_studio_orderable_children.map(&:id)
    assert hidden.reload.trashed_at.present?
    assert_select "button", text: "Move up", count: 0
    assert_select "button", text: "Move down", count: 0
  end

  test "creating a kit uses record and lands on the editor" do
    sign_in @user
    switch_to_root(@root)

    title = "Winter brief #{SecureRandom.hex(4)}"
    assert_difference -> { RecordingStudioPresskits::PressKit.count }, 1 do
      post recording_studio_presskits.press_kits_path, params: {
        press_kit: { title: title, description: "Not on the create form" }
      }
    end

    press_kit = RecordingStudioPresskits::PressKit.where(title: title).order(:created_at).last
    kit = RecordingStudioPresskits::KitQuery.for_root(@root).find { |recording| recording.recordable_id == press_kit.id }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert_equal @root, kit.parent_recording
    assert_nil press_kit.description
  end

  test "header edit shows the title and short description" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_rounded_default_layout
    assert_select "title", text: "Header"
    assert_select "h1", text: "Header"
    assert_layout_back_button(label: "Back to kit", href: recording_studio_presskits.edit_press_kit_path(kit))
    assert_page_nav_without_access
    assert_select "input[name='press_kit[title]'][value='Spring launch']"
    assert_select "textarea[name='press_kit[description]']", text: "Doors at noon."
    assert_select "input[name='press_kit[cover_style]'][value='color']"
    assert_select "input[name='press_kit[cover_color]'][value='#1F2937'][type='radio'][checked]"
    assert_select "input[name='press_kit[cover_text_color]'][value='auto'][type='radio'][checked]"
    assert_includes response.body, "Colour"
    assert_includes response.body, "/280 characters"
    update = css_select("#presskits-header-actions button[type=submit]").first
    assert_equal "Update", update.text.squish
    assert_equal "default", update["data-fp-style"]
    assert_includes update["class"], "fp-button"
    form = css_select("form[action='#{recording_studio_presskits.press_kit_header_path(kit)}']").first
    form_html = form.to_html
    assert_includes form_html, "flat-pack--unsaved-changes"
    assert_includes form_html, 'name="press_kit[cover_color]"'
    assert_includes form_html, 'name="press_kit[cover_text_color]"'
    assert_operator form_html.index('name="press_kit[title]"'), :<, form_html.index('name="press_kit[description]"')
    assert_operator form_html.index('name="press_kit[description]"'), :<, form_html.index("Update")
    refute_includes response.body, "md:grid-cols-2"
    refute_select "a", text: "Cancel"
    preview = css_select("#presskits-header-edit-preview").first
    assert_includes preview["class"], "border-[var(--card-border-color)]"
    assert_select "#presskits-header-edit-preview h1", text: "Spring launch"
    assert_select "#presskits-header-edit-preview p", text: "Doors at noon."
    assert_select "button", text: "Remove", count: 0
  end

  test "saving the kit header uses revise" do
    kit = record_kit("Spring launch")
    original_id = kit.recordable_id
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_path(kit), params: {
      press_kit: { title: "Nope", description: "Nope" }
    }
    assert_response :not_found
    assert_equal "Spring launch", kit.reload.recordable.title

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: {
        title: "Spring launch, take two",
        description: "Doors at noon.",
        cover_style: "color",
        cover_color: "#BFDBFE",
        cover_text_color: "#111827",
        decoy: "nope"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    follow_redirect!
    assert_response :success
    assert_select "p", text: "Saved. That's what people see first."
    assert_select "h1", text: "Header"
    assert_select "input[name='press_kit[title]'][value='Spring launch, take two']"
    assert_select "textarea[name='press_kit[description]']", text: "Doors at noon."
    kit.reload
    assert_not_equal original_id, kit.recordable_id
    assert_equal "Spring launch, take two", kit.recordable.title
    assert_equal "Doors at noon.", kit.recordable.description
    assert_equal "color", kit.recordable.cover_style
    assert_equal "#BFDBFE", kit.recordable.cover_color
    assert_equal "#111827", kit.recordable.cover_text_color
    refute_includes kit.recordable.attributes.values, "nope"
    original = RecordingStudioPresskits::PressKit.find(original_id)
    assert_equal "Spring launch", original.title
    assert_nil original.description

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "h1", text: "Spring launch, take two"
    assert_select "#presskits-kit-header [data-cover-eyebrow]", text: "Press kit"
    refute_includes css_select("#presskits-kit-header").text, "Doors at noon"
    assert_select "#presskits-editor-preview", count: 1
    assert_select "#presskits-kit-header input", count: 0
  end

  test "a blank kit title stays unsaved" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Keep this." }
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "  ", description: "New words" }
    }
    assert_response :unprocessable_entity
    assert_select "h1", text: "Header"
    assert_includes response.body, "Give it a name so you can find it later."
    assert_includes response.body, "New words"
    kit.reload
    assert_equal "Spring launch", kit.recordable.title
    assert_equal "Keep this.", kit.recordable.description
  end

  test "a description past 280 characters stays unsaved" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Keep this." }
    too_long = "a" * 281
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch", description: too_long }
    }
    assert_response :unprocessable_entity
    assert_select "h1", text: "Header"
    assert_includes response.body, "Keep that description short. 280 characters is the limit."
    assert_includes response.body, too_long
    kit.reload
    assert_equal "Spring launch", kit.recordable.title
    assert_equal "Keep this.", kit.recordable.description
  end

  test "a blank description clears and drops the preview" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_header_path(kit), params: {
      press_kit: { title: "Spring launch", description: "   " }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_header_path(kit)
    follow_redirect!
    assert_response :success
    assert_nil kit.reload.recordable.description
    assert_select "textarea[name='press_kit[description]']", text: ""

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    refute_includes css_select("#presskits-kit-header").text, "Doors at noon"
    assert_select "#presskits-editor-preview"
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_header_path(kit)}'][role='menuitem'][aria-label='Edit heading']"
  end

  test "header edit refuses someone without access" do
    kit = record_kit("Spring launch")
    outsider = User.create!(
      email: "header-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :forbidden
  end

  test "a missing kit has no header screen" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(SecureRandom.uuid)
    assert_response :not_found
  end

  test "the live header keeps the short description off the colour band" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    record_block(kit, "Hero")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_equal "Doors at noon.", kit.reload.recordable.description
    assert_select "#presskits-kit-header [data-cover-eyebrow]", text: "Press kit"
    refute_includes css_select("#presskits-kit-header").text, "Doors at noon"
    refute_includes css_select("#presskits-section-list").to_html, "Doors at noon."
    assert_select "#presskits-editor-preview", text: /Hero/
  end

  test "unauthenticated visitors are sent to sign in" do
    get recording_studio_presskits.press_kits_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated users without access are forbidden" do
    outsider = User.create!(
      email: "no-access-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :forbidden
  end

  test "images section saves a title and subtitle and shows attached photos" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::Images.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::Images" }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success

    section = images_section(kit)
    assert_equal "Images", section.recordable.title
    assert_nil section.recordable.subtitle
    assert_select ".fp-section-title h2", text: "Images"
    assert_select "#presskits-section-placeholder"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "label", text: "Title"
    assert_select "label", text: "Subtitle"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Images"
    assert_select "input[name='kit_section[subtitle]']"
    refute_select "input[name='images[title]']"
    refute_select "input[name='images[caption]']"
    assert_operator response.body.index('name="kit_section[title]"'), :<, response.body.index('name="kit_section[subtitle]"')
    assert_heading_form_save_button(kit, section)
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_includes heading, ">Update<"
    refute_includes heading, ">Upload<"
    refute_includes heading, 'type="file"'
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "h1", text: "Images"
    refute_select "input[name='kit_section[title]']"
    refute_select "#presskits-section-preview"
    assert_includes response.body, "No images yet."
    refute_includes response.body, ">Save<"
    assert_select "a", text: "Add from library"
    assert_select "[data-controller='recording-studio-presskits--library-upload']", count: 1
    assert_select "[data-controller='recording-studio-presskits--library-upload'] button[type='button']", text: "Upload"
    assert_select "input[type=file][accept='image/*']"
    refute_select "[data-controller='recording-studio-attachable--upload']"
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    assert_includes response.body, "Caption, credit, and alt live on the library photo"
    assert_select "#presskits-section-content-form", count: 0
    refute section_editor_cancel?

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Press photos", subtitle: "Doors at noon", decoy: "nope" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)
    follow_redirect!
    section.reload
    assert_equal "Press photos", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle
    refute_includes section.recordable.attributes.values, "nope"
    assert_select "title", text: "Press photos"
    assert_select "h1", text: "Section heading"
    assert_select "input[name='kit_section[title]'][value='Press photos']"
    assert_select "input[name='kit_section[subtitle]'][value='Doors at noon']"
    assert_heading_form_save_button(kit, section)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select ".fp-section-title h2", text: "Press photos"
    assert_select ".fp-section-title", text: /Doors at noon/

    attachment = attach_image(section, "stage.jpg")
    images = section_content(section)
    placement = images.library_placements.first.placement_recording
    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "img[alt='stage']"
    upload_form = css_select("[data-controller='recording-studio-presskits--library-upload']").first.to_html
    assert_includes upload_form, 'enctype="multipart/form-data"'
    refute_includes upload_form, "attachment_collection"
    assert_select "form#attachment-collection-#{images.id}"
    assert_select "input[name='attachment_collection[rows][][caption]'][form='attachment-collection-#{images.id}']"
    assert_select "input[name='attachment_collection[rows][][credit]']"
    assert_select "input[name='attachment_collection[rows][][alt_text]']"
    assert_select "label", text: "Credit"
    assert_select "label", text: "Alt text"
    assert_select "button", text: "Save"
    assert_select "button", text: "Remove from here"
    refute_select "button", text: "Trash"
    refute_includes response.body, "No images yet."

    signed = css_select("input[name='attachment_collection[signed_editor]']").first["value"]
    return_to = recording_studio_presskits.edit_press_kit_section_path(kit, section)
    patch recording_studio_attachable.recording_placements_path(images), params: {
      redirect_mode: "return_to",
      return_to: return_to,
      attachment_collection: {
        signed_editor: signed,
        rows: [{
          recording_id: placement.id,
          caption: "Stage left",
          credit: "Ada",
          alt_text: "The stage"
        }]
      }
    }
    assert_response :redirect
    follow_redirect!
    attachment.reload
    assert_equal "Stage left", attachment.recordable.caption
    assert_equal "Ada", attachment.recordable.credit
    assert_equal "The stage", attachment.recordable.alt_text

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    images_link = "#presskits-section-list a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, section)}']"
    assert_select images_link, text: "Images"
    assert_nil css_select(images_link).first["title"]
    images_row = css_select("#presskits-section-list [role='listitem']").find { |item| item["id"] == section.id }
    assert_includes images_row.to_html, 'data-flat-pack--icon-name-value="photo"'
    refute_includes images_row.to_html, "arrows-up-down"
    assert_includes images_row["class"], "!items-center"
    assert_select "#presskits-editor-preview img[alt='The stage']"
    assert_select "#presskits-editor-preview .fp-section-title h2", text: "Press photos"
    assert_select "#presskits-editor-preview .fp-section-title", text: /Doors at noon/
    assert_select "#presskits-editor-preview a[href='#press-photos'][aria-label='Copy link to Press photos']"

    publish_images_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-images"
    assert_response :success
    assert_select ".fp-section-title#press-photos h2", text: "Press photos"
    assert_select ".fp-section-title", text: /Doors at noon/
    assert_select "img[alt='The stage']"
    assert response.body.index("Press photos") < response.body.index("alt=\"The stage\"")

    delete recording_studio_presskits.press_kit_section_library_image_path(kit, section, placement)
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_select "img[alt='The stage']", count: 0
    assert_select "img[alt='stage']", count: 0
    assert_nil attachment.reload.trashed_at
    assert_nil section.reload.trashed_at
    assert_empty images.reload.library_placements
  end

  test "adding a quotes section shows quotes and omits a blank body" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::QuoteSection.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::QuoteSection" }
    end
    follow_redirect!
    assert_response :success
    section = quote_section(kit)
    assert_equal "Quotes", section.recordable.title
    assert_select ".fp-section-title h2", text: "Quotes"
    assert_select "#presskits-section-placeholder"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Quotes"
    assert_select "input[name='kit_section[subtitle]']"
    assert_heading_form_save_button(kit, section)
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index('name="kit_section[subtitle]"')
    refute_includes heading, ">Quote<"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "h1", text: "Quotes"
    assert_select "#presskits-section-actions button[type=submit]" do
      assert_select "span", text: "Quote"
      assert_select "[data-flat-pack--icon-name-value='plus']", count: 1
    end
    assert_select "button", text: "Add quote", count: 0
    refute_select "input[name='kit_section[title]']"
    assert_select "textarea[name='quote[body]']", count: 0
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    assert_layout_back_button(label: "Back to kit", href: recording_studio_presskits.edit_press_kit_path(kit))
    refute section_editor_cancel?
    actions = css_select("#presskits-section-actions").to_html
    assert_includes actions, ">Quote<"
    refute_includes actions, "Cancel"
    refute_includes actions, ">Update<"
    assert_select "#presskits-section-content-form", count: 0
    assert_includes css_select("#presskits-section-fields").first.to_html, 'id="presskits-section-actions"'
    assert_includes css_select("#presskits-section-fields").first.to_html, 'data-flat-pack--icon-name-value="plus"'

    assert_difference -> { RecordingStudioPresskits::Quote.count }, 1 do
      post recording_studio_presskits.press_kit_section_quotes_path(kit, section)
    end
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Quote added."
    assert_select "h1", text: "Quote"
    assert_select "label", text: "Quote"
    assert_select "textarea[name='quote[body]']"
    assert_select "label", text: "Name"
    assert_select "input[name='quote[name]']"
    assert_select "label", text: "Role"
    assert_select "input[name='quote[role]']"
    assert_select "label", text: "Organisation"
    assert_select "input[name='quote[organisation]']"
    save = css_select("#presskits-quote-actions button[type=submit]").first
    assert_equal "Save", save.text.squish
    assert_equal "primary", save["data-fp-style"]
    refute_includes response.body, "flat-pack--unsaved-changes"
    assert_select "a[aria-label='Remove quote']", count: 0
    assert_select "button", text: "Upload"
    assert_select "form[data-controller='recording-studio-attachable--upload']"
    assert_match(/remove-button-template-value="&lt;button/, response.body)
    cancel = css_select("a").find { |node| node.text.include?("Cancel") }
    assert_equal recording_studio_presskits.edit_press_kit_section_path(kit, section), cancel["href"]

    first = live_quotes(section).first
    patch recording_studio_presskits.press_kit_section_quote_path(kit, section, first), params: {
      quote: {
        body: "A line worth printing",
        name: "Ada Lovelace",
        role: "Editor",
        organisation: "Press",
        decoy: "nope"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_quote_path(kit, section, first)
    follow_redirect!
    assert_equal "A line worth printing", first.reload.recordable.body
    assert_equal "Ada Lovelace", first.recordable.name
    refute_includes first.recordable.attributes.values, "nope"
    assert_equal recording_studio_presskits.edit_press_kit_section_quote_path(kit, section, first), path

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    quote_link = css_select("a[href='#{recording_studio_presskits.edit_press_kit_section_quote_path(kit, section, first)}']").first
    quote_lines = quote_link.css("span").map { |node| node.text.strip }
    assert_equal ["A line worth printing", "Ada Lovelace"], quote_lines
    assert_includes quote_link.css("span").first["class"], "truncate"
    assert_includes quote_link.css("span").last["class"], "text-(--surface-muted-content-color)"
    assert_select "textarea[name='quote[body]']", count: 0
    assert_select "button[aria-label='Remove quote']"
    fields = quotes_editor_grid
    assert_includes fields.to_html, 'data-flat-pack--icon-name-value="plus"'
    assert_operator fields.to_html.index(">Quote<"), :<, fields.to_html.index("A line worth printing")
    assert_operator fields.text.index("A line worth printing"), :<, fields.text.index("Ada Lovelace")
    refute_select "#presskits-section-preview"
    refute_select "input[name='kit_section[title]']"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "figure.fp-quote blockquote.text-xl", text: "A line worth printing"
    assert_select "figcaption", text: "— Ada Lovelace, Editor, Press"
    assert_includes css_select("figure.fp-quote").first["class"], "[&>blockquote]:border-l-[length:var(--quote-border-width)]"

    publish_quote_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-quotes"
    assert_response :success
    assert_select ".fp-section-title h2", text: "Quotes"
    assert_select "figure.fp-quote blockquote.text-xl", text: "A line worth printing"
    assert_select "figcaption", text: "— Ada Lovelace, Editor, Press"
    assert_includes css_select("figure.fp-quote").first["class"], "[&>blockquote]:border-l-[length:var(--quote-border-width)]"

    assert_difference -> { RecordingStudioPresskits::Quote.count }, 1 do
      post recording_studio_presskits.press_kit_section_quotes_path(kit, section)
    end
    second = live_quotes(section).last
    patch recording_studio_presskits.press_kit_section_quote_path(kit, section, second), params: {
      quote: { body: "Second line", name: "Grace Hopper" }
    }
    patch recording_studio_presskits.press_kit_section_quote_order_path(kit, section), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!
    assert_response :success
    assert_equal [second.id, first.id], live_quotes(section).map(&:id)

    delete recording_studio_presskits.press_kit_section_quote_path(kit, section, second)
    follow_redirect!
    assert_response :success
    assert second.reload.trashed_at.present?
    assert_nil section.reload.trashed_at
    assert_nil first.reload.trashed_at
    assert_includes response.body, "A line worth printing"
    assert_includes response.body, "Ada Lovelace"
    refute_includes response.body, "Grace Hopper"
    refute_includes response.body, "Second line"

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    text = content_section(kit, RecordingStudioPresskits::Text)
    follow_redirect!
    assert_response :success
    get recording_studio_presskits.edit_press_kit_section_path(kit, text)
    assert_select "button", text: "Update"
    assert_select "button", text: "Quote", count: 0

    post recording_studio_presskits.press_kit_section_quotes_path(kit, section)
    blank = section_content(section).child_recordings.where(
      recordable_type: "RecordingStudioPresskits::Quote",
      trashed_at: nil
    ).order(:created_at).last
    patch recording_studio_presskits.press_kit_section_quote_path(kit, section, blank), params: {
      quote: { body: "   ", name: "Hidden byline" }
    }
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-quotes"
    assert_response :success
    assert_operator response.body.index("A line worth printing"), :<, response.body.index("Ada Lovelace")
    refute_includes response.body, "Hidden byline"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    hidden_link = css_select("a").find { |node| node.text.include?("Hidden byline") }
    hidden_lines = hidden_link.css("span").map { |node| node.text.strip }
    assert_equal ["Quote", "Hidden byline"], hidden_lines
    get recording_studio_presskits.edit_press_kit_path(kit)
    refute_includes css_select("#presskits-editor-preview").text, "Hidden byline"
    assert_includes css_select("#presskits-editor-preview").text, "A line worth printing"

    post recording_studio_presskits.press_kit_section_quotes_path(kit, section)
    nameless = section_content(section).child_recordings.where(
      recordable_type: "RecordingStudioPresskits::Quote",
      trashed_at: nil
    ).order(:created_at).last
    patch recording_studio_presskits.press_kit_section_quote_path(kit, section, nameless), params: {
      quote: { body: "No byline here", name: "" }
    }
    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    nameless_lines = css_select("a[href='#{recording_studio_presskits.edit_press_kit_section_quote_path(kit, section, nameless)}']").first.css("span").map { |node| node.text.strip }
    assert_equal ["No byline here"], nameless_lines
  end

  test "empty sections show a placeholder in the editor and stay off the public kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    follow_redirect!
    assert_response :success
    assert_select "#presskits-editor-preview"
    assert_select "#presskits-section-placeholder"
    refute_section_preview_card

    images = images_section(kit)
    patch recording_studio_presskits.press_kit_section_path(kit, images), params: {
      kit_section: { title: "Stills" }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "#presskits-editor-preview .fp-section-title h2", text: "Stills"
    assert_select "#presskits-section-placeholder"
    assert_select "#presskits-editor-preview img", count: 0

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::QuoteSection" }
    follow_redirect!
    assert_select "#presskits-section-placeholder"

    quotes = quote_section(kit)
    patch recording_studio_presskits.press_kit_section_path(kit, quotes), params: {
      kit_section: { subtitle: "One line" }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select ".fp-section-title h2", text: "Quotes"
    assert_select ".fp-section-title", text: /One line/

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::VideoSection" }
    follow_redirect!
    assert_select "#presskits-section-placeholder"

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    follow_redirect!
    assert_select "#presskits-editor-preview", text: /Launch notes/

    text = content_section(kit, RecordingStudioPresskits::Text)
    RecordingStudioPresskits::Text.where(id: section_content(text).recordable.id).update_all(body: "<p><br></p>")
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-section-#{text.id} #presskits-section-placeholder"
    get recording_studio_presskits.edit_press_kit_section_path(kit, text)
    refute_section_preview_card
  end

  test "a video section links to a new video and plays saved videos" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::VideoSection.count }, 1 do
      assert_no_difference -> { RecordingStudioVideo::Video.count } do
        post recording_studio_presskits.press_kit_sections_path(kit),
             params: { type: "RecordingStudioPresskits::VideoSection" }
      end
    end
    follow_redirect!
    assert_response :success
    section = video_section(kit)
    new_video = recording_studio_presskits.new_press_kit_section_video_path(kit, section)
    assert_equal "Video", section.recordable.title
    assert_select ".fp-section-title h2", text: "Video"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]']"
    assert_select "input[name='kit_section[subtitle]']"
    assert_select "#presskits-section-update button[type=submit]", text: "Update"
    assert_section_editor_tabs
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")
    refute_includes heading, "video[url]"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "h1", text: "Video"
    refute_select "input[name='kit_section[title]']"
    assert_select "#presskits-section-content-form", count: 0
    assert_includes css_select("#presskits-section-fields").first.to_html, new_video
    assert_select "#presskits-section-actions a[href='#{new_video}']" do
      assert_select "span", text: "Video"
      assert_select "[data-flat-pack--icon-name-value='plus']", count: 1
    end
    refute_includes css_select("#presskits-section-actions").to_html, "<form"

    assert_no_difference -> { RecordingStudioVideo::Video.count } do
      get new_video
    end
    assert_response :success
    assert_video_fields
    assert_select "h1", text: "Video"
    assert_select "iframe", count: 0

    post recording_studio_presskits.press_kit_section_videos_path(kit, section), params: {
      video: {
        title: "Me at the zoo",
        url: "https://www.youtube.com/watch?v=jNQXAC9IVRw",
        description: "The first video uploaded to YouTube."
      }
    }
    video = RecordingStudioPresskits::VideoSection.active_videos(section_content(section)).first
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_video_path(kit, section, video)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Video added."
    assert_video_fields
    assert_includes response.body, "https://www.youtube-nocookie.com/embed/jNQXAC9IVRw"
    assert_select "h1", text: "Me at the zoo"

    post recording_studio_presskits.press_kit_section_videos_path(kit, section), params: {
      video: {
        title: "Second reel",
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        description: "Another clip"
      }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_equal "Video", section.reload.recordable.title
    refute_select "#presskits-section-preview"
    refute_select "input[name='kit_section[title]']"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Trailer", subtitle: "Two minutes" }
    }
    assert_redirected_to recording_studio_presskits.heading_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    get recording_studio_presskits.edit_press_kit_path(kit)
    preview = css_select("#presskits-editor-preview").first.to_html
    zoo = "https://www.youtube-nocookie.com/embed/jNQXAC9IVRw"
    rick = "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
    assert_operator preview.index("Trailer"), :<, preview.index(zoo)
    assert_operator preview.index("Two minutes"), :<, preview.index(zoo)
    assert_operator preview.index("Me at the zoo"), :<, preview.index(zoo)
    assert_operator preview.index(zoo), :<, preview.index(rick)
    assert_includes preview, "The first video uploaded to YouTube."
    assert_includes preview, "Second reel"

    publish_video_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-videos"
    assert_response :success
    assert_operator response.body.index("Trailer"), :<, response.body.index(zoo)
    assert_operator response.body.index("Two minutes"), :<, response.body.index(zoo)
    assert_includes response.body, zoo
    assert_includes response.body, rick
  end

  test "a vimeo url stays on the video form and a text section has no video button" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::VideoSection" }
    follow_redirect!
    section = video_section(kit)
    vimeo = "https://vimeo.com/76979871"

    assert_no_difference -> { RecordingStudioVideo::Video.count } do
      post recording_studio_presskits.press_kit_section_videos_path(kit, section), params: {
        video: { title: "Nope", url: vimeo, description: "Not this one" }
      }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "That URL is not from a supported provider."
    assert_includes response.body, vimeo

    post recording_studio_presskits.press_kit_section_videos_path(kit, section), params: {
      video: { title: "Me at the zoo", url: "https://www.youtube.com/watch?v=jNQXAC9IVRw", description: "Kept" }
    }
    video = RecordingStudioPresskits::VideoSection.active_videos(section_content(section)).first
    follow_redirect!
    assert_no_difference -> { RecordingStudioVideo::Video.count } do
      patch recording_studio_presskits.press_kit_section_video_path(kit, section, video), params: {
        video: { title: "Me at the zoo", url: vimeo, description: "Kept" }
      }
    end
    assert_response :unprocessable_entity
    assert_equal "https://www.youtube.com/watch?v=jNQXAC9IVRw", video.reload.recordable.url
    assert_includes response.body, "That URL is not from a supported provider."

    get recording_studio_presskits.edit_press_kit_section_video_path(kit, section, SecureRandom.uuid)
    assert_response :not_found

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    text = content_section(kit, RecordingStudioPresskits::Text)
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_section_path(kit, text)
    assert_response :success
    assert_select "#presskits-section-actions", count: 0
    assert_select "a", text: "Video", count: 0

    post recording_studio_presskits.press_kit_section_videos_path(kit, text), params: {
      video: { url: "https://www.youtube.com/watch?v=jNQXAC9IVRw" }
    }
    assert_response :not_found
  end

  private

  def assert_heading_form_save_button(kit, section)
    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_response :success
    form = css_select("#presskits-section-title-form").first
    assert_equal recording_studio_presskits.press_kit_section_path(kit, section), form["action"]
    assert_equal "flat-pack--unsaved-changes", form["data-controller"]
    button = css_select("#presskits-section-title-form #presskits-section-update button[type=submit]").first
    assert_equal "Update", button.text.squish
    assert_equal "default", button["data-fp-style"]
    assert_equal "submit", button["data-flat-pack--unsaved-changes-target"]
    assert_includes button["class"], "fp-button"
    settings = form.to_html
    assert_operator settings.index('name="kit_section[title]"'), :<, settings.index('name="kit_section[subtitle]"')
    assert_operator settings.index('name="kit_section[subtitle]"'), :<, settings.index(">Update<")
    refute_includes settings, "<fieldset"
    refute_select "legend", text: "Heading"
    assert_select "#presskits-section-title-form" do
      assert_select "#presskits-section-update button[type=submit]", text: "Update"
      assert_select "input[name='kit_section[title]']"
      assert_select "input[name='kit_section[subtitle]']"
    end
  end

  def assert_section_editor_tabs
    refute_select "#presskits-section-tabs"
  end

  def assert_section_menu_icon(type_name, icon_name)
    link = css_select("a[href*='type=#{ERB::Util.url_encode(type_name)}']").first
    assert link, "expected a + Section item for #{type_name}"
    assert_select link, "[data-flat-pack--icon-name-value='#{icon_name}']"
  end

  def quotes_editor_grid
    css_select("#presskits-section-fields").first
  end

  def images_editor_grid
    quotes_editor_grid
  end

  def section_editor_columns
    [quotes_editor_grid].compact
  end

  def refute_section_preview_card
    refute_select "#presskits-section-preview"
  end

  def assert_section_preview_card
    refute_select "#presskits-section-preview"
  end

  def section_editor_cancel?
    css_select("#presskits-section-fields a, #presskits-section-fields button").any? { |node| node.text.include?("Cancel") }
  end

  def quote_section(kit)
    content_section(kit, RecordingStudioPresskits::QuoteSection)
  end

  def video_section(kit)
    content_section(kit, RecordingStudioPresskits::VideoSection)
  end

  def assert_video_fields
    assert_select "input[name='video[title]']"
    assert_select "input[name='video[url]']"
    assert_select "textarea[name='video[description]']"
    assert_includes response.body, "Paste a link to a supported video, such as YouTube."
  end

  def publish_video_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-videos", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end

  def live_quotes(section)
    section_content(section).recording_studio_orderable_children.reject { |child| child.trashed_at.present? }
  end

  def publish_quote_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-quotes", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end

  def images_section(kit)
    content_section(kit, RecordingStudioPresskits::Images)
  end

  def content_section(kit, klass)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(klass)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def attach_image(section, filename)
    content = section_content(section)
    library = content.root_recording.image_library(actor: @user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")),
      filename: filename,
      content_type: "image/jpeg"
    )
    photo = library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
    photo.revise_attachment_metadata(actor: @user, alt_text: File.basename(filename, ".*"))
    result = RecordingStudioPresskits::SectionImages.place(
      images_recording: content,
      attachment_recording: photo,
      actor: @user
    )
    raise result.error if result.failure?

    photo
  end

  def publish_images_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-images", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end

  def assert_library_sidebar
    assert_select "[data-controller='flat-pack--sidebar-layout']"
    assert_select "button[aria-expanded='true'] span.fp-sidebar-label", text: "Library"
    assert_select "a[data-flat-pack-sidebar-item='true'][href='#{recording_studio_presskits.credits_path}'] span.fp-sidebar-label",
                  text: "Credits"
    assert_select "a[data-flat-pack-sidebar-item='true'] span.fp-sidebar-label", text: "Images"
    assert_select "a.fp-button[href='#{recording_studio_presskits.credits_path}']", count: 0
    assert_select "button[aria-label='Open sidebar'][data-action='click->flat-pack--sidebar-layout#toggleMobile']"
  end

  def assert_presskit_create_button
    assert_select "a[href='#{recording_studio_presskits.new_press_kit_path}']" do
      assert_select "[data-flat-pack--icon-name-value='plus']", count: 1
      assert_select "span", text: "Presskit"
    end
    refute_includes response.body, "New press kit"
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
end
