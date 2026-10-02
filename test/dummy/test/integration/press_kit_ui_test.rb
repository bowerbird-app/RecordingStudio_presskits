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
    assert_select "input[name='press_kit[title]']", count: 0
    assert_select "button", text: "Save", count: 0
    assert_includes response.body, "Spring launch"
    assert_includes response.body, "presskits-section-dropdown"
    assert_select "#presskits-editor-actions span", text: "Section"
    assert_select "#presskits-editor-actions [data-flat-pack--icon-name-value='plus']", count: 1
    section_button = css_select("#presskits-section-dropdown button").first
    assert_includes section_button["class"], "bg-[var(--button-primary-background-color)]"
    refute_select "button#presskits-section-dropdown[disabled]"
    assert_select "a[href*='type=RecordingStudioPresskits%3A%3AText']", text: "Text"
    actions_html = css_select("#presskits-editor-actions").to_html
    assert_operator actions_html.index("presskits-section-dropdown"), :<, actions_html.index("publishable_quick_actions_")
    grid_html = css_select("#presskits-editor-grid").to_html
    assert_includes grid_html, "md:grid-cols-2"
    refute_includes grid_html, 'name="press_kit[title]"'
    refute_includes grid_html, "presskits-section-dropdown"
    refute_includes grid_html, "publishable_quick_actions_"
    assert_includes response.body, "Preview"
    refute_includes response.body, 'name="press_kit[title]"'
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
    assert_select "input[name='press_kit[title]']", count: 0
    assert_select "button", text: "Save", count: 0
    assert_includes response.body, "presskits-section-dropdown"
    assert_includes css_select("#presskits-section-dropdown button").first["class"], "bg-[var(--button-primary-background-color)]"
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
    section_cards = css_select("#presskits-section-list > .rounded-lg")
    assert_equal 1, section_cards.size
    card = section_cards.first
    assert_includes card["class"], "border-[var(--card-border-color)]"
    list = css_select("#presskits-section-list [role='list']").first
    assert_equal "flat-pack--list-orderable", list["data-controller"]
    assert_includes list["class"], "divide-y"
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

    hero = RecordingStudioPresskits::KitQuery.live_children(kit).find { |child| child.recordable.title == "Hero" }
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
    assert_equal "Hero, revised", hero.reload.recordable.title
    refute_includes hero.recordable.attributes.values, "nope"
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

    section = RecordingStudioPresskits::KitQuery.live_children(kit).find { |child|
      child.recordable.is_a?(RecordingStudioPresskits::Text)
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Section added."
    assert_page_nav_without_access
    assert_equal RecordingStudioPresskits::Text.opening_body, section.recordable.body
    assert_select "input[type=hidden][name='text[body]'][value=?]", RecordingStudioPresskits::Text.opening_body
    assert_includes response.body, "&quot;preset&quot;:&quot;content&quot;"
    assert_includes response.body, "&quot;toolbar&quot;:&quot;standard&quot;"
    assert_select "h1", text: "Text"
    assert_select "label", text: "Text", count: 0
    assert_select "h2", text: "Launch notes", count: 0
    assert_select "strong", text: "one-sheet", count: 0
    assert_select "li", text: "Photos", count: 0
    assert_select ".flat-pack-richtext--view-mode", count: 0
    assert_select "button", text: "Update"
    assert_select "#presskits-section-actions button", text: "Upload", count: 0
    assert_select "button", text: "Save", count: 0
    cancel = css_select("a[href='#{recording_studio_presskits.edit_press_kit_path(kit)}']").find { |node| node.text.include?("Cancel") }
    assert_includes cancel.text, "Cancel"
    assert_includes cancel["class"], "bg-[var(--button-default-background-color)]"
    form_html = css_select("form[action='#{recording_studio_presskits.press_kit_section_path(kit, section)}']").to_html
    assert_operator form_html.index("Update"), :<, form_html.index("name=\"text[body]\"")
    grid_html = css_select("#presskits-section-actions ~ .grid").to_html
    assert_includes grid_html, "grid-cols-1"
    refute_includes grid_html, "md:grid-cols-2"
    refute_includes grid_html, ">Update<"
    refute_includes grid_html, ">Cancel<"
    assert_select "button", text: "Remove", count: 0

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      text: { body: "", decoy: "nope" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Could not save that section."
    assert_equal RecordingStudioPresskits::Text.opening_body, section.reload.recordable.body

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      text: {
        body: "<h2>Set list</h2><p>Line two</p><script>alert(1)</script>",
        decoy: "nope"
      }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_response :success
    assert_includes section.reload.recordable.body, "<h2>Set list</h2>"
    assert_includes section.recordable.body, "<p>Line two</p>"
    refute_match(/<script/i, section.recordable.body)
    refute_includes section.recordable.body, "alert(1)"
    refute_includes section.recordable.attributes.values, "nope"
    assert_select "h2", text: "Set list", count: 0
    assert_select "p", text: "Line two", count: 0
    assert_select ".flat-pack-richtext--view-mode", count: 0
    refute_includes response.body, "nope"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_path(kit, section)}']", text: "Text"
    assert_select "h2", text: "Set list"
    assert_select "p", text: "Line two"
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

    delete recording_studio_presskits.press_kit_section_path(kit, hero)
    follow_redirect!

    assert_response :success
    refute_includes response.body, "Hero"
    refute_includes RecordingStudioPresskits::KitQuery.live_children(kit).map(&:id), hero.id
    assert hero.reload.trashed_at.present?
    assert_equal true, hero.trash_root
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
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.live_children(kit).map(&:id)
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
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.live_children(kit).map(&:id)
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
      post recording_studio_presskits.press_kits_path, params: { press_kit: { title: title } }
    end

    press_kit = RecordingStudioPresskits::PressKit.where(title: title).order(:created_at).last
    kit = RecordingStudioPresskits::KitQuery.for_root(@root).find { |recording| recording.recordable_id == press_kit.id }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert_equal @root, kit.parent_recording
  end

  test "saving the kit title uses revise" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_path(kit), params: { press_kit: { title: "Spring launch, take two" } }
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Spring launch, take two"
    assert_select "h1", text: "Spring launch, take two"
    assert_equal "Spring launch, take two", kit.reload.recordable.title
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

  test "images section saves a caption and shows attached photos" do
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
    assert_select "h1", text: "Images"
    assert_select "label", text: "Caption"
    assert_select "input[name='images[caption]']"
    assert_select "form[data-controller='recording-studio-attachable--upload']", count: 1
    assert_select "#presskits-section-actions button[type='button']", text: "Upload"
    assert_select "input[type=file][accept='image/*'][data-recording-studio-attachable--upload-target='input']"
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    actions = css_select("#presskits-section-actions").to_html
    assert_operator actions.index("Update"), :<, actions.index("Cancel")
    assert_operator actions.index("Cancel"), :<, actions.index("Upload")
    assert_match(/remove-button-template-value="&lt;button/, response.body)
    refute_includes response.body, ">Remove\">"
    assert_select "#presskits-editor-preview", count: 0

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      images: { caption: "Press photos", decoy: "nope" }
    }
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    follow_redirect!
    assert_equal "Press photos", section.reload.recordable.caption
    refute_includes section.recordable.attributes.values, "nope"

    attachment = attach_image(section, "stage.jpg")
    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "img[alt='stage']"
    assert response.body.index("alt=\"stage\"") < response.body.index("name=\"images[caption]\"")
    assert_select "a[href='#{recording_studio_presskits.press_kit_section_image_path(kit, section, attachment)}'][data-turbo-method='delete']"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-editor-preview img[alt='stage']"
    assert_select "#presskits-editor-preview", text: /Press photos/

    publish_images_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-images"
    assert_response :success
    assert_includes response.body, "Press photos"
    assert_select "img[alt='stage']"
    assert response.body.index("alt=\"stage\"") < response.body.index("Press photos")

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
    assert_select "button", text: "Add quote"
    assert_select "button", text: "Update", count: 0
    assert_select "textarea[name='quote[body]']", count: 0
    refute_includes response.body, "Drag images here"
    refute_includes response.body, "Choose images"
    cancel = css_select("a[href='#{recording_studio_presskits.edit_press_kit_path(kit)}']").find { |node|
      node.text.include?("Cancel")
    }
    assert_includes cancel.text, "Cancel"
    grid = quotes_editor_grid
    assert grid
    assert_equal 2, grid.element_children.size
    assert_includes grid.element_children.first.text, "Add quote"
    refute_includes grid.element_children.last.text, "Add quote"

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
    assert_select "button", text: "Save"
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
    assert_select "a[href='#{recording_studio_presskits.edit_press_kit_section_quote_path(kit, section, first)}']", text: "Ada Lovelace"
    assert_select "textarea[name='quote[body]']", count: 0
    assert_select "button[aria-label='Remove quote']"
    grid = quotes_editor_grid
    columns = grid.element_children
    assert_equal 2, columns.size
    refute_includes columns.first.text, "A line worth printing"
    assert_includes columns.last.text, "A line worth printing"
    assert_includes columns.last.text, "Ada Lovelace"
    assert_includes columns.last.text, "Editor, Press"

    publish_quote_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-quotes"
    assert_response :success
    assert_operator response.body.index("A line worth printing"), :<, response.body.index("Ada Lovelace")
    assert_includes response.body, "Editor, Press"

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
    assert_select "a", text: "Ada Lovelace"
    refute_includes response.body, "Grace Hopper"

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::Text" }
    follow_redirect!
    assert_response :success
    assert_select "button", text: "Update"
    assert_select "button", text: "Add quote", count: 0

    post recording_studio_presskits.press_kit_section_quotes_path(kit, section)
    blank = section.child_recordings.where(
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
    assert_includes columns.first.text, "Hidden byline"
    refute_includes columns.last.text, "Hidden byline"
    assert_includes columns.last.text, "A line worth printing"
  end

  private

  def quotes_editor_grid
    css_select(".grid").find { |node| node["class"].to_s.include?("md:grid-cols-2") }
  end

  def quote_section(kit)
    RecordingStudioPresskits::KitQuery.live_children(kit).find do |child|
      child.recordable.is_a?(RecordingStudioPresskits::QuoteSection)
    end
  end

  def live_quotes(section)
    section.recording_studio_orderable_children.reject { |child| child.trashed_at.present? }
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
    RecordingStudioPresskits::KitQuery.live_children(kit).find do |child|
      child.recordable.is_a?(RecordingStudioPresskits::Images)
    end
  end

  def attach_image(section, filename)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: filename,
      content_type: "image/jpeg"
    )
    section.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
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
    kit.record(FakeBlock, parent_recording: kit) { |fake_block| fake_block.title = title }
  end
end
