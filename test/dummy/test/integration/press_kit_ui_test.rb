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
    assert_match(/Presskit.*squares-2x2.*table-cells/m, response.body)
    assert_select "[data-flat-pack--icon-name-value='photo']", count: 1
    assert_includes response.body, "bg-(--card-background-muted-color)"
    assert_select "a[aria-label='Cards'] [data-flat-pack--icon-name-value='squares-2x2']", count: 1
    assert_select "a[aria-label='Table'] [data-flat-pack--icon-name-value='table-cells']", count: 1
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
    assert_page_nav_close
    assert_page_nav_without_access

    get recording_studio_presskits.press_kits_path(view: "table")
    assert_response :success
    assert_rounded_default_layout
    assert_includes response.body, "Spring launch"
    assert_select "a[href='#{edit_href}']", text: "Spring launch"
    assert_includes response.body, "<table"
    assert_presskit_create_button
    assert_match(/Presskit.*squares-2x2.*table-cells/m, response.body)
    assert_select "[data-flat-pack--icon-name-value='photo']", count: 0
    refute_includes response.body, ">Cards<"
    refute_includes response.body, ">Table<"
  end

  test "card view renders a cover image when the kit provides a safe url" do
    record_kit("Spring launch")
    RecordingStudioPresskits::PressKit.define_method(:cover_image_url) { "https://cdn.example/cover.jpg" }
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "img[src='https://cdn.example/cover.jpg'][alt='']", count: 1
    assert_select "[data-flat-pack--icon-name-value='photo']", count: 0
  ensure
    if RecordingStudioPresskits::PressKit.method_defined?(:cover_image_url)
      RecordingStudioPresskits::PressKit.remove_method(:cover_image_url)
    end
  end

  test "empty index explains what to do next" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_includes response.body, "Nothing here yet"
    assert_includes response.body, "Make a press kit"
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
    assert_select "#presskits-editor-actions span", text: "Section"
    assert_includes response.body, "Hero"
    assert_includes response.body, "Quotes"
    assert_match(/Hero.*Quotes/m, response.body)
    assert_page_nav_close
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
    assert_select "#presskits-editor-grid h1", count: 0
    header_path = recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_select "#presskits-kit-header a[href='#{header_path}']", text: "Header"
    assert_select "#presskits-kit-header input", count: 0
    assert_select "#presskits-kit-header textarea", count: 0
    assert_select "#presskits-kit-header button", count: 0
    refute_includes response.body, "0/280 characters"
    header_row = css_select("#presskits-header-row").first
    assert_includes header_row.to_html, 'data-flat-pack--icon-name-value="bars-3-bottom-left"'
    refute_includes header_row.to_html, "arrows-up-down"
    refute_includes header_row.to_html, "trash"
    refute_includes css_select("#presskits-kit-rows").first["class"].to_s, "divide-y"
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "presskits-section-dropdown"
    assert_select "#presskits-editor-actions span", text: "Section"
    assert_select "#presskits-editor-actions [data-flat-pack--icon-name-value='plus']", count: 1
    section_button = css_select("#presskits-section-dropdown button").first
    assert_equal "primary", section_button["data-fp-style"]
    assert_includes section_button["class"], "fp-button"
    refute_select "button#presskits-section-dropdown[disabled]"
    assert_select "a[href*='type=RecordingStudioPresskits%3A%3AText']", text: "Text"
    assert_section_menu_icon("RecordingStudioPresskits::Text", "document-text")
    assert_section_menu_icon("RecordingStudioPresskits::Images", "photo")
    assert_section_menu_icon("RecordingStudioPresskits::QuoteSection", "chat-bubble-bottom-center-text")
    assert_section_menu_icon("RecordingStudioPresskits::VideoSection", "video-camera")
    actions_html = css_select("#presskits-editor-actions").to_html
    assert_operator actions_html.index("presskits-section-dropdown"), :<, actions_html.index("publishable_quick_actions_")
    grid_html = css_select("#presskits-editor-grid").to_html
    assert_includes grid_html, "md:grid-cols-2"
    refute_includes grid_html, 'name="press_kit[title]"'
    refute_includes grid_html, 'name="press_kit[description]"'
    assert_includes grid_html, "presskits-kit-header"
    assert_includes grid_html, ">Header<"
    refute_includes grid_html, "presskits-section-dropdown"
    refute_includes grid_html, "publishable_quick_actions_"
    assert_includes response.body, "Preview"
    assert response.body.index('id="presskits-editor-actions"') < response.body.index('id="presskits-editor-grid"')
    assert response.body.index('id="presskits-editor-grid"') < response.body.index('id="presskits-kit-header"')
    refute_select "a[href='#{recording_studio_presskits.preview_press_kit_path(kit)}']"
    refute_includes response.body, "presskits-section-picker"
    refute_includes response.body, "Pick what to drop into this kit."
    refute_includes response.body, "Fake block"
    refute_includes response.body, "No sections yet"
    assert_select "#publishable_quick_actions_#{kit.id} [role=menu]", count: 1
    assert_access_slot_only
    assert_includes response.body, "md:grid-cols-2"
    assert_includes response.body, "gap-6"
    assert_includes response.body, "items-start"
    assert_includes response.body, "publishable_quick_actions_"
    assert_includes response.body, "Draft"
    refute_includes response.body, "EditButtonComponent"
  end

  test "empty kit editor keeps add and the publish control" do
    kit = record_kit("Empty launch")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "h1", text: "Empty launch"
    header_path = recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_select "#presskits-kit-header a[href='#{header_path}']", text: "Header"
    assert_select "#presskits-kit-header input", count: 0
    assert_select "#presskits-kit-header textarea", count: 0
    assert_select "input[name='press_kit[title]']", count: 0
    assert_select "button", text: "Save", count: 0
    assert_includes response.body, "presskits-section-dropdown"
    empty_section_button = css_select("#presskits-section-dropdown button").first
    assert_equal "primary", empty_section_button["data-fp-style"]
    assert_includes empty_section_button["class"], "fp-button"
    assert_select "#presskits-section-list", count: 0
    assert_select "#presskits-editor-preview", count: 0
    assert_includes response.body, "Preview"
    refute_includes response.body, "No sections yet"
    refute_includes response.body, "presskits-section-picker"
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
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, hero)}']", text: "Fake block"
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, quotes)}']", text: "Fake block"
    refute_includes response.body, "Fake block: Hero"
    refute_includes response.body, "Fake block: Quotes"
    assert_select "button", text: "Move up", count: 0
    assert_select "button", text: "Move down", count: 0
    shell = css_select("#presskits-section-list").first
    assert_equal "recording-studio-presskits--section-order", shell["data-controller"]
    assert_includes shell["data-action"], "list:reordered->recording-studio-presskits--section-order#save"
    assert_equal recording_studio_presskits.press_kit_order_path(kit), shell["data-recording-studio-presskits--section-order-url-value"]
    list_card = css_select("#presskits-editor-grid [class*='rounded-']").find { |node| node.at_css("#presskits-kit-header") }
    assert list_card
    assert_includes list_card["class"], "border-[var(--card-border-color)]"
    assert list_card.at_css("#presskits-section-list")
    assert_includes css_select("#presskits-kit-rows").first["class"], "divide-y"
    header_row = css_select("#presskits-header-row").first
    assert_select header_row, "a", text: "Header"
    assert_includes header_row.to_html, 'data-flat-pack--icon-name-value="bars-3-bottom-left"'
    refute_includes header_row.to_html, "arrows-up-down"
    refute_includes header_row.to_html, "trash"
    assert_select header_row, "button", count: 0
    refute css_select("#presskits-section-list #presskits-header-row").any?
    list = css_select("#presskits-section-list [role='list']").first
    assert_equal "flat-pack--list-orderable", list["data-controller"]
    assert_includes list["class"], "flat-pack-list--orderable"
    assert_includes list["class"], "flat-pack-list-divided"
    items = css_select("#presskits-section-list [role='listitem']")
    assert_equal [hero.id, quotes.id], items.map { |item| item["id"] }
    items.each do |item|
      assert_includes item.to_html, 'data-flat-pack--icon-name-value="arrows-up-down"'
      assert_includes item.to_html, 'data-flat-pack--icon-name-value="trash"'
      assert_select item, "button[aria-label='Remove']", count: 1
      assert_select item, "input[name='_method'][value='delete']", count: 1
    end
    preview = css_select("#presskits-editor-preview").first
    assert_includes preview["class"], "border-[var(--card-border-color)]"
    assert_includes preview.text, "Hero"
    assert_includes preview.text, "Quotes"
    assert_select "#presskits-header-preview", count: 0
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
    section_grid = css_select(".grid").find { |node| node["class"].to_s.include?("md:grid-cols-2") && node.text.include?("Hero") }
    assert section_grid
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
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, hero)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_includes response.body, "Hero"
    assert_select "button", text: "Remove", count: 0
    assert_page_nav_without_access
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
    assert_includes response.body, "Hero, revised"
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
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_page_nav_without_access
    assert_nil section.recordable.title
    assert_nil section.recordable.subtitle
    assert_equal RecordingStudioPresskits::Text.opening_body, section_content(section).recordable.body
    assert_select "label", text: "Title"
    assert_select "label", text: "Subtitle"
    assert_select "label", text: "Body"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Text"
    assert_nil css_select("input[name='kit_section[title]']").first["value"]
    assert_select "input[type=hidden][name='text[body]'][value=?]", RecordingStudioPresskits::Text.opening_body
    assert_includes response.body, "&quot;preset&quot;:&quot;content&quot;"
    assert_includes response.body, "&quot;toolbar&quot;:&quot;standard&quot;"
    assert_select "h1", text: "Text"
    assert_select "label", text: "Text", count: 0
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Text"
    assert_select "#presskits-section-preview h2", text: "Launch notes"
    assert_select "#presskits-section-preview strong", text: "one-sheet"
    assert_select "#presskits-section-preview li", text: "Photos"
    assert_select "#presskits-section-preview .flat-pack-richtext--view-mode"
    assert_heading_form_save_button(kit, section)
    assert_select "button", text: "Upload", count: 0
    assert_select "button", text: "Save", count: 0
    assert_includes response.body, "Back to kit"
    refute section_editor_cancel?
    content_form = css_select("#presskits-section-content-form").first
    settings_form = css_select("#presskits-section-title-form").first
    assert_equal "flat-pack--unsaved-changes", content_form["data-controller"]
    content_html = content_form.to_html
    settings_html = settings_form.to_html
    assert_includes content_html, 'name="text[body]"'
    assert_operator content_html.index(">Body<"), :<, content_html.index(">Update<")
    refute_includes content_html, 'name="kit_section[title]"'
    refute_includes settings_html, 'name="text[body]"'
    assert_operator settings_html.index(">Title<"), :<, settings_html.index(">Subtitle<")
    assert_operator settings_html.index(">Subtitle<"), :<, settings_html.index(">Update<")
    assert_select "#presskits-section-content-panel", text: /Body/
    assert_select "#presskits-section-title-panel", text: /Title/
    columns = section_editor_columns
    assert_equal 2, columns.size
    assert_includes columns.first.to_html, 'id="presskits-section-update"'
    assert_includes columns.first.to_html, 'name="kit_section[title]"'
    assert_includes columns.first.to_html, 'name="text[body]"'
    refute_includes columns.last.to_html, 'name="kit_section[title]"'
    refute_includes columns.last.to_html, ">Update<"
    assert_includes columns.last["id"], "presskits-section-preview"
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
    assert_nil RecordingStudioPresskits::KitSection.find(original_section_id).title
    assert_includes content.recordable.body, "<h2>Set list</h2>"
    assert_includes content.recordable.body, "<p>Line two</p>"
    refute_match(/<script/i, content.recordable.body)
    refute_includes content.recordable.body, "alert(1)"
    refute_includes section.recordable.attributes.values, "nope"
    refute_includes content.recordable.attributes.values, "nope"
    assert_select "title", text: "Launch notes"
    assert_select "h1", text: "Text"
    assert_select "input[name='kit_section[title]'][value=?]", "Launch notes"
    assert_select "input[name='kit_section[subtitle]'][value=?]", "Doors at noon"
    assert_select "label", text: "Title"
    assert_select "label", text: "Body"
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Launch notes"
    assert_select "#presskits-section-preview h2", text: "Set list"
    assert_select "#presskits-section-preview p", text: "Line two"
    assert_select "#presskits-section-preview .flat-pack-richtext--view-mode"
    refute_includes response.body, "nope"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Launch notes tonight", subtitle: "Doors at noon" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
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
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, section)}']", text: "Text"
    assert_select ".fp-section-title#launch-notes h2", text: "Launch notes"
    assert_select ".fp-section-title#launch-notes" do |titles|
      refute_includes titles.first.parent["class"].to_s, "gap-4"
    end
    assert_select "a[href='#launch-notes'][aria-label='Copy link to Launch notes']"
    assert_select "[data-controller='flat-pack--section-title-anchor']"
    assert_select "h2", text: "Set list"
    assert_select "p", text: "Line two"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "   ", subtitle: "   " },
      text: { body: section_content(section).recordable.body }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_nil section.reload.recordable.title
    assert_nil section.recordable.subtitle

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
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
    assert_includes response.body, "Back to kit"
    assert_page_nav_without_access
    assert_select "input[name='press_kit[title]'][value='Spring launch']"
    assert_select "textarea[name='press_kit[description]']", text: "Doors at noon."
    assert_includes response.body, "/280 characters"
    update = css_select("#presskits-header-actions button[type=submit]").first
    assert_equal "Update", update.text.squish
    assert_equal "primary", update["data-fp-style"]
    assert_includes update["class"], "fp-button"
    cancel = css_select("a[href='#{recording_studio_presskits.edit_press_kit_path(kit)}']").find { |node|
      node.text.include?("Cancel")
    }
    assert_equal "default", cancel["data-fp-style"]
    assert_includes cancel["class"], "fp-button"
    form = css_select("form[action='#{recording_studio_presskits.press_kit_header_path(kit)}']").first
    form_html = form.to_html
    refute_includes form_html, "flat-pack--unsaved-changes"
    assert_operator form_html.index("Update"), :<, form_html.index('name="press_kit[title]"')
    grid_html = css_select("#presskits-header-actions ~ .grid").to_html
    assert_includes grid_html, "grid-cols-1"
    assert_includes grid_html, "md:grid-cols-2"
    columns = css_select("#presskits-header-actions ~ .grid > *")
    assert_equal 2, columns.size
    assert_includes columns.first.to_html, 'name="press_kit[title]"'
    assert_includes columns.first.to_html, 'name="press_kit[description]"'
    refute_includes columns.first.to_html, "presskits-header-edit-preview"
    refute_includes columns.last.to_html, 'name="press_kit[title]"'
    assert_includes columns.last.to_html, "presskits-header-edit-preview"
    preview = css_select("#presskits-header-edit-preview").first
    assert_includes preview["class"], "border-[var(--card-border-color)]"
    assert_select "#presskits-header-edit-preview h2", text: "Spring launch"
    assert_select "#presskits-header-edit-preview p", text: "Doors at noon."
    refute_includes grid_html, ">Update<"
    refute_includes grid_html, ">Cancel<"
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
    refute_includes kit.recordable.attributes.values, "nope"
    original = RecordingStudioPresskits::PressKit.find(original_id)
    assert_equal "Spring launch", original.title
    assert_nil original.description

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "h1", text: "Spring launch, take two"
    assert_select "#presskits-header-preview", text: "Doors at noon."
    assert_select "#presskits-editor-preview", count: 1
    assert_select "#presskits-section-list", count: 0
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
    assert_select "#presskits-header-preview", count: 0
    assert_select "#presskits-editor-preview", count: 0
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_header_path(kit)}']", text: "Header"
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

  test "a short description previews above the sections" do
    kit = record_kit("Spring launch")
    @root.revise(kit) { |press_kit| press_kit.description = "Doors at noon." }
    record_block(kit, "Hero")
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-header-preview", text: "Doors at noon."
    preview = css_select("#presskits-editor-preview").first
    assert_operator preview.text.index("Doors at noon."), :<, preview.text.index("Hero")
    refute_includes css_select("#presskits-section-list").to_html, "Doors at noon."
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
    assert_nil section.recordable.title
    assert_nil section.recordable.subtitle
    assert_select "h1", text: "Images"
    assert_select "label", text: "Title"
    assert_select "label", text: "Subtitle"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Images"
    assert_select "input[name='kit_section[subtitle]']"
    refute_select "input[name='images[title]']"
    refute_select "input[name='images[caption]']"
    assert_operator response.body.index('name="kit_section[title]"'), :<, response.body.index('name="kit_section[subtitle]"')
    grid = images_editor_grid
    columns = grid.element_children
    assert_equal 2, columns.size
    assert_includes columns.first.to_html, 'id="presskits-section-update"'
    assert_includes columns.first.to_html, 'name="kit_section[title]"'
    assert_includes columns.first.to_html, 'name="kit_section[subtitle]"'
    refute_includes columns.last.to_html, 'name="kit_section[title]"'
    refute_includes columns.last.to_html, ">Update<"
    refute_select "#presskits-section-preview h2", text: "Preview"
    refute_includes columns.last.text, "Preview"
    assert_includes response.body, "No images yet."
    refute_includes response.body, ">Save<"
    assert_select "[data-controller='recording-studio-attachable--upload']", count: 1
    refute_select "form[data-controller='recording-studio-attachable--upload']"
    assert_select "[data-controller='recording-studio-attachable--upload'] button[type='button']", text: "Upload"
    assert_select "input[type=file][accept='image/*'][data-recording-studio-attachable--upload-target='input']"
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    column = columns.first.to_html
    assert_heading_form_save_button(kit, section)
    assert_select "#presskits-section-content-form", count: 0
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_includes heading, ">Update<"
    refute_includes heading, ">Upload<"
    refute_includes heading, 'type="file"'
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")
    assert_operator column.index(">Upload<"), :<, column.index('name="kit_section[title]"')
    assert_operator column.index('name="kit_section[subtitle]"'), :<, column.index(">Update<")
    refute_includes column, "Cancel"
    refute section_editor_cancel?
    assert_match(/remove-button-template-value="&lt;button/, response.body)
    refute_includes response.body, ">Remove\">"
    assert_select "#presskits-editor-preview", count: 0

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Press photos", subtitle: "Doors at noon", decoy: "nope" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    section.reload
    assert_equal "Press photos", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle
    refute_includes section.recordable.attributes.values, "nope"
    assert_select "title", text: "Press photos"
    assert_select "h1", text: "Images"
    assert_select "input[name='kit_section[title]'][value='Press photos']"
    assert_select "input[name='kit_section[subtitle]'][value='Doors at noon']"
    assert_heading_form_save_button(kit, section)
    refute_select "#presskits-section-preview h2", text: "Preview"
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Press photos"
    assert_select "#presskits-section-preview .fp-section-title", text: /Doors at noon/

    attachment = attach_image(section, "stage.jpg")
    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "img[alt='stage']"
    images = section_content(section)
    assert response.body.index("alt=\"stage\"") < response.body.index('name="kit_section[title]"')
    upload_form = css_select("[data-controller='recording-studio-attachable--upload']").first.to_html
    refute_includes upload_form, "attachment_collection"
    assert_select "form#attachment-collection-#{images.id}"
    assert_select "input[name='attachment_collection[rows][][caption]'][form='attachment-collection-#{images.id}']"
    assert_select "input[name='attachment_collection[rows][][credit]']"
    assert_select "input[name='attachment_collection[rows][][alt_text]']"
    assert_select "label", text: "Credit"
    assert_select "label", text: "Alt text"
    assert_heading_form_save_button(kit, section)
    assert_select "button", text: "Save"
    assert_select "button", text: "Trash"
    refute_includes response.body, "No images yet."

    signed = css_select("input[name='attachment_collection[signed_editor]']").first["value"]
    return_to = recording_studio_presskits.edit_press_kit_section_path(kit, section)
    patch recording_studio_attachable.recording_attachment_collection_path(images), params: {
      redirect_mode: "return_to",
      return_to: return_to,
      attachment_collection: {
        signed_editor: signed,
        rows: [{
          recording_id: attachment.id,
          caption: "Stage left",
          credit: "Ada",
          alt_text: "The stage"
        }]
      }
    }
    assert_redirected_to return_to
    follow_redirect!
    attachment.reload
    assert_equal "Stage left", attachment.recordable.caption
    assert_equal "Ada", attachment.recordable.credit
    assert_equal "The stage", attachment.recordable.alt_text

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, section)}']", text: "Images"
    assert_select "#presskits-editor-preview img[alt='stage']"
    assert_select "#presskits-editor-preview .fp-section-title h2", text: "Press photos"
    assert_select "#presskits-editor-preview .fp-section-title", text: /Doors at noon/
    assert_select "#presskits-editor-preview a[href='#press-photos'][aria-label='Copy link to Press photos']"

    publish_images_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-images"
    assert_response :success
    assert_select ".fp-section-title#press-photos h2", text: "Press photos"
    assert_select ".fp-section-title", text: /Doors at noon/
    assert_select "img[alt='stage']"
    assert response.body.index("Press photos") < response.body.index("alt=\"stage\"")

    delete recording_studio_presskits.press_kit_section_image_path(kit, section, attachment)
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_select "img[alt='stage']", count: 0
    assert attachment.reload.trashed_at.present?
    assert_nil section.reload.trashed_at
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
    assert_select "h1", text: "Quotes"
    assert_select "#presskits-section-actions button[type=submit]" do
      assert_select "span", text: "Quote"
      assert_select "[data-flat-pack--icon-name-value='plus']", count: 1
    end
    assert_select "button", text: "Add quote", count: 0
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Quotes"
    assert_select "input[name='kit_section[subtitle]']"
    assert_heading_form_save_button(kit, section)
    assert_select "textarea[name='quote[body]']", count: 0
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    assert_includes response.body, "Back to kit"
    refute section_editor_cancel?
    actions = css_select("#presskits-section-actions").to_html
    assert_includes actions, ">Quote<"
    refute_includes actions, "Cancel"
    refute_includes actions, ">Update<"
    assert_select "#presskits-section-content-form", count: 0
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index('name="kit_section[subtitle]"')
    refute_includes heading, ">Quote<"
    columns = section_editor_columns
    assert_equal 2, columns.size
    assert_operator columns.first.to_html.index(">Quote<"), :<, columns.first.to_html.index(">Update<")
    assert_includes columns.first.to_html, 'name="kit_section[title]"'
    assert_includes columns.first.to_html, 'id="presskits-section-actions"'
    assert_includes columns.first.to_html, 'data-flat-pack--icon-name-value="plus"'
    refute_includes columns.last.to_html, 'data-flat-pack--icon-name-value="plus"'
    refute_includes columns.last.text, "Cancel"

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
    grid = quotes_editor_grid
    columns = grid.element_children
    assert_equal 2, columns.size
    assert_includes columns.first.to_html, 'data-flat-pack--icon-name-value="plus"'
    refute_includes columns.last.to_html, 'data-flat-pack--icon-name-value="plus"'
    heading = css_select("#presskits-section-title-form").first.to_html
    refute_includes heading, "Remove quote"
    assert_operator columns.first.to_html.index(">Quote<"), :<, columns.first.to_html.index(">Update<")
    assert_operator columns.first.to_html.index(">Quote<"), :<, columns.first.to_html.index("A line worth printing")
    assert_operator columns.first.text.index("A line worth printing"), :<, columns.first.text.index("Ada Lovelace")
    assert_select columns.last, "figure.fp-quote blockquote.text-xl", text: "A line worth printing"
    assert_select columns.last, "figcaption", text: "— Ada Lovelace, Editor, Press"
    assert_includes columns.last.at_css("figure.fp-quote")["class"], "[&>blockquote]:border-l-[length:var(--quote-border-width)]"

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
    follow_redirect!
    assert_response :success
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
    columns = quotes_editor_grid.element_children
    hidden_link = css_select("a").find { |node| node.text.include?("Hidden byline") }
    hidden_lines = hidden_link.css("span").map { |node| node.text.strip }
    assert_equal ["Quote", "Hidden byline"], hidden_lines
    refute_includes columns.last.text, "Hidden byline"
    assert_includes columns.last.text, "A line worth printing"

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

  test "the preview card stays hidden until a section has something to show" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Images" }
    follow_redirect!
    assert_response :success
    refute_section_preview_card

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-editor-preview", count: 0

    images = images_section(kit)
    patch recording_studio_presskits.press_kit_section_path(kit, images), params: {
      kit_section: { title: "Stills" }
    }
    follow_redirect!
    assert_section_preview_card
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Stills"
    assert_select "#presskits-section-preview img", count: 0

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "#presskits-editor-preview .fp-section-title h2", text: "Stills"
    assert_select "#presskits-editor-preview img", count: 0

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::QuoteSection" }
    follow_redirect!
    refute_section_preview_card

    quotes = quote_section(kit)
    patch recording_studio_presskits.press_kit_section_path(kit, quotes), params: {
      kit_section: { subtitle: "One line" }
    }
    follow_redirect!
    assert_section_preview_card
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Quotes"
    assert_select "#presskits-section-preview .fp-section-title", text: /One line/

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::VideoSection" }
    follow_redirect!
    refute_section_preview_card

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    follow_redirect!
    assert_section_preview_card
    assert_select "#presskits-section-preview", text: /Launch notes/

    text = content_section(kit, RecordingStudioPresskits::Text)
    RecordingStudioPresskits::Text.where(id: section_content(text).recordable.id).update_all(body: "<p><br></p>")
    get recording_studio_presskits.edit_press_kit_section_path(kit, text)
    assert_response :success
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
    assert_select "h1", text: "Video"
    assert_select "input[name='kit_section[title]']"
    assert_select "input[name='kit_section[subtitle]']"
    assert_select "#presskits-section-update button[type=submit]", text: "Update"
    assert_section_editor_tabs
    assert_select "#presskits-section-content-form", count: 0
    content_panel = css_select("#presskits-section-content-panel").first.to_html
    assert_includes content_panel, new_video
    refute_includes content_panel, 'name="kit_section[title]"'
    heading = css_select("#presskits-section-title-form").first.to_html
    assert_operator heading.index('name="kit_section[title]"'), :<, heading.index(">Update<")
    refute_includes heading, "video[url]"
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
    assert_nil section.recordable.title
    assert_select "#presskits-section-preview .fp-section-title h2", text: "Video"
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Video"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Trailer", subtitle: "Two minutes" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    preview = css_select("#presskits-section-preview").first.to_html
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
    assert_section_editor_tabs
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
    assert_select "#presskits-section-tabs[data-controller='flat-pack--tabs']"
    labels = css_select("#presskits-section-tabs [role=tab]").map { |tab| tab.text.squish }
    assert_equal [ "Content", "Section title" ], labels
    assert_equal "true", css_select("#presskits-section-content-tab").first["aria-selected"]
    assert_equal "false", css_select("#presskits-section-title-tab").first["aria-selected"]
    assert_nil css_select("#presskits-section-content-panel").first["hidden"]
    assert css_select("#presskits-section-title-panel").first["hidden"]
    tablist = css_select("#presskits-section-tabs [role=tablist]").first
    assert_equal "default", tablist["data-fp-style"]
    assert_includes tablist["class"], "fp-pill-style"
    assert_includes tablist["class"], "fp-pill-button-slots"
  end

  def assert_section_menu_icon(type_name, icon_name)
    link = css_select("a[href*='type=#{ERB::Util.url_encode(type_name)}']").first
    assert link, "expected a + Section item for #{type_name}"
    assert_select link, "[data-flat-pack--icon-name-value='#{icon_name}']"
  end

  def quotes_editor_grid
    css_select("#presskits-section-grid").first
  end

  def images_editor_grid
    quotes_editor_grid
  end

  def section_editor_columns
    quotes_editor_grid.element_children
  end

  def refute_section_preview_card
    column = css_select("#presskits-section-preview").first
    assert column
    assert_nil column.at_css("[class*='card-border-color']")
  end

  def assert_section_preview_card
    column = css_select("#presskits-section-preview").first
    assert column&.at_css("[class*='card-border-color']")
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
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: filename,
      content_type: "image/jpeg"
    )
    section_content(section).record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
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
