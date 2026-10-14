# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class MenuSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LONG_TITLE = "The very long story of how this press kit came to be and why the title does not fit"

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "menu-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Menu Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "adding a menu from the editor stores Contents and the jump subtitle" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::MenuSection.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::MenuSection" }
    end
    follow_redirect!
    assert_response :success

    section = menu_section(kit)
    assert_equal "Contents", section.recordable.title
    assert_equal "Jump to any section of the press kit.", section.recordable.subtitle
    menu = section_content(section).recordable
    assert_equal "grid", menu.layout
    assert menu.show_counts
    assert menu.show_icons
    assert_equal({}, menu.items)
    assert_select "#presskits-section-placeholder", text: /Nothing to jump to yet/
    refute_select "nav[data-presskits-menu]"
  end

  test "the public menu links visible sections in kit order and matches heading ids" do
    kit = record_kit("Spring launch")
    about = add_text(kit, "About the launch")
    photos = add_images(kit, "Photos")
    attach_image!(section_content(photos), "one.jpg")
    attach_image!(section_content(photos), "two.jpg")
    duplicate = add_text(kit, "Photos")
    blank = add_text(kit, "???")
    long = add_text(kit, LONG_TITLE)
    add_list(kit, "Empty lines")
    add_images(kit, "Shelf")
    menu = add_menu(kit)
    other_menu = add_menu(kit)

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)
    assert_response :success

    expected = [
      ["About the launch", "about-the-launch", "document-text", nil],
      ["Photos", "photos", "photo", "2 images"],
      ["Photos", "photos-2", "document-text", nil],
      ["???", "section-#{blank.id}", "document-text", nil],
      [LONG_TITLE, long_anchor(long), "document-text", nil]
    ]
    menus = css_select("nav[data-presskits-menu]")
    assert_equal 2, menus.size
    assert_menu(menus[0], "contents", expected)
    assert_menu(menus[1], "contents-2", expected)
    assert_equal "contents", heading_id(menu)
    assert_equal "contents-2", heading_id(other_menu)
    assert_text_heading_id(about, "about-the-launch")
    assert_text_heading_id(blank, "section-#{blank.id}")
    assert_text_heading_id(duplicate, "photos-2")
    assert_section_title_id("Photos", "photos")

    long_link = menu_links(menus[0]).find { |link| link.text.include?(LONG_TITLE) }
    assert_includes long_link["class"], "justify-center"
    assert_includes long_link["class"], "inline-flex"
    assert_includes long_link["class"], "line-clamp-2"
    assert_equal LONG_TITLE, long_link["title"]
    refute_includes long_link["class"], "truncate"

    refute_includes menus[0].text, "Empty lines"
    refute_includes menus[0].text, "Shelf"
    refute_includes menus[0].text, "Contents"
  end

  test "reordering sections changes jump order and which duplicate keeps the base id" do
    kit = record_kit("Spring launch")
    first = add_text(kit, "Photos")
    notes = add_text(kit, "Notes")
    second = add_text(kit, "Photos")
    menu = add_menu(kit)

    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id, notes.id, menu.id],
      actor: @user
    )

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)

    hrefs = menu_links(css_select("nav[data-presskits-menu]").first).map { |link| link["href"] }
    assert_equal ["#photos", "#photos-2", "#notes"], hrefs
    assert_equal "photos", RecordingStudioPresskits.section_anchor_id(second)
    assert_equal "photos-2", RecordingStudioPresskits.section_anchor_id(first)
  end

  test "hidden sections, counts, icons, and both layouts" do
    kit = record_kit("Spring launch")
    about = add_text(kit, "About the launch")
    photos = add_images(kit, "Photos")
    attach_image!(section_content(photos), "one.jpg")
    menu = add_menu(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_section_path(kit, menu)
    assert_response :success
    assert_select "h1", text: "Menu"
    assert_select "input[name='menu_section[layout]'][value='grid'][checked]"
    assert_select "input[name='menu_section[show_counts]'][value='0']"
    assert_select "input[name='menu_section[show_icons]'][value='0']"
    assert_select "input[name='menu_section[items][#{about.id}][label]'][placeholder='About the launch']"
    assert_select "input[name='menu_section[items][#{about.id}][shown]'][value='0']"
    assert_select "legend", text: "Sections"
    refute_select "legend", text: "Leave these out"

    patch recording_studio_presskits.press_kit_section_path(kit, menu), params: {
      menu_section: menu_params(
        "list",
        "0",
        "0",
        about.id => { label: "", shown: "0" },
        photos.id => { label: "", shown: "1" }
      )
    }
    assert_response :redirect
    saved = section_content(menu).recordable.reload
    assert_equal "list", saved.layout
    refute saved.show_counts
    refute saved.show_icons
    assert_equal true, saved.items[about.id.to_s]["hidden"]

    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    assert_includes nav.at_css("ul")["class"], "grid-cols-1"
    refute_includes nav.at_css("ul")["class"], "minmax"
    hrefs = menu_links(nav).map { |link| link["href"] }
    assert_equal ["#photos"], hrefs
    assert_select "nav[data-presskits-menu] svg", count: 0
    assert_select "nav[data-presskits-menu] [aria-label='1 image']", count: 0

    patch recording_studio_presskits.press_kit_section_path(kit, menu), params: {
      menu_section: menu_params(
        "grid",
        "1",
        "1",
        about.id => { label: "", shown: "1" },
        photos.id => { label: "", shown: "1" }
      )
    }
    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    assert_includes nav.at_css("ul")["class"], "grid-cols-[repeat(auto-fill,minmax(14rem,1fr))]"
    hrefs = menu_links(nav).map { |link| link["href"] }
    assert_equal ["#about-the-launch", "#photos"], hrefs
    assert_equal "photo", nav.at_css("a[href='#photos'] [data-flat-pack--icon-name-value]")["data-flat-pack--icon-name-value"]
    assert_equal "1 image", nav.at_css("[aria-label='1 image']")["aria-label"]
    assert_equal "1", nav.at_css("[aria-label='1 image']").text.strip
    assert_equal({}, section_content(menu).recordable.reload.items)
  end

  test "overrides fall back, hide, ignore stale ids, and keep matching after rename and reorder" do
    kit = record_kit("Spring launch")
    about = add_text(kit, "About the launch")
    photos = add_text(kit, "Photos")
    again = add_text(kit, "Photos")
    menu = add_menu(kit)
    RecordingStudioPresskits::MenuSection.where(id: section_content(menu).recordable_id).update_all(
      items: {
        about.id => { "label" => "Bio", "hidden" => false },
        "00000000-0000-0000-0000-000000000000" => { "label" => "Ghost", "hidden" => false }
      }
    )
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    assert_equal "Bio", menu_links(nav).first.text.squish
    refute_includes nav.text, "Ghost"

    patch recording_studio_presskits.press_kit_section_path(kit, menu), params: {
      menu_section: menu_params(
        "grid",
        "1",
        "1",
        about.id => { label: "Bio", shown: "1" },
        photos.id => { label: "   ", shown: "1" },
        again.id => { label: "", shown: "0" },
        "00000000-0000-0000-0000-000000000000" => { label: "Ghost", shown: "1" }
      )
    }

    saved = section_content(menu).recordable.reload
    assert_equal({ "label" => "Bio", "hidden" => false }, saved.items[about.id.to_s])
    refute saved.items.key?(photos.id.to_s)
    assert_equal true, saved.items[again.id.to_s]["hidden"]
    refute saved.items.key?("00000000-0000-0000-0000-000000000000")

    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    links = menu_links(nav)
    assert_equal ["#about-the-launch", "#photos"], links.map { |link| link["href"] }
    bio = links[0]
    assert_equal "Bio", bio.text.squish
    assert_equal "About the launch", bio["title"]
    assert_equal "About the launch", bio["aria-label"]
    assert_equal "Photos", links[1].text.squish
    assert_nil links[1]["aria-label"]
    refute_includes nav.text, "Ghost"

    patch recording_studio_presskits.press_kit_section_path(kit, menu), params: {
      menu_section: menu_params(
        "grid",
        "1",
        "1",
        about.id => { label: "", shown: "1" },
        photos.id => { label: "", shown: "1" },
        again.id => { label: "", shown: "1" }
      )
    }
    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    about_link = menu_links(nav).find { |link| link["href"] == "#about-the-launch" }
    assert_equal "About the launch", about_link.text.squish
    assert_nil about_link["aria-label"]

    patch recording_studio_presskits.press_kit_section_path(kit, menu), params: {
      menu_section: menu_params(
        "grid",
        "1",
        "1",
        about.id => { label: "Bio", shown: "1" },
        photos.id => { label: "", shown: "1" },
        again.id => { label: "Extra", shown: "1" }
      )
    }
    @root.revise(about) { |section| section.title = "Launch story" }
    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [again.id, photos.id, about.id, menu.id],
      actor: @user
    )

    get recording_studio_presskits.preview_press_kit_path(kit)
    nav = css_select("nav[data-presskits-menu]").first
    links = menu_links(nav)
    assert_equal ["#photos", "#photos-2", "#launch-story"], links.map { |link| link["href"] }
    assert_equal "Extra", links[0].text.squish
    assert_equal "Photos", links[0]["title"]
    assert_equal "Photos", links[0]["aria-label"]
    assert_equal "Photos", links[1].text.squish
    assert_nil links[1]["aria-label"]
    assert_equal "Bio", links[2].text.squish
    assert_equal "Launch story", links[2]["title"]
    assert_equal "Launch story", links[2]["aria-label"]
    assert_equal "##{RecordingStudioPresskits.section_anchor_id(about.reload)}", links[2]["href"]
    assert_equal "##{RecordingStudioPresskits.section_anchor_id(again.reload)}", links[0]["href"]
  end

  test "a menu with nothing to list stays off the page" do
    kit = record_kit("Spring launch")
    add_list(kit, "Empty lines")
    add_menu(kit)
    add_menu(kit)

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.preview_press_kit_path(kit)

    refute_select "nav[data-presskits-menu]"
    assert_select "#presskits-public-sections", text: /Nothing to show yet/
  end

  private

  def assert_menu(nav, labelledby, expected)
    assert_equal labelledby, nav["aria-labelledby"]
    assert css_select("[id='#{labelledby}']").any?
    assert_equal "navigation", nav["role"] unless nav["role"].nil?
    items = nav.css("ul > li")
    assert_equal expected.size, items.size
    expected.each_with_index do |(label, anchor, icon, count), index|
      link = items[index].at_css("a")
      assert_equal label, link.text.squish
      assert_equal "##{anchor}", link["href"]
      assert_equal label, link["title"]
      assert_nil link["aria-label"]
      assert_equal "default", link["data-fp-style"]
      assert_includes link["class"], "fp-button"
      icon_node = link.at_css("svg[data-flat-pack--icon-name-value='#{icon}']")
      assert icon_node
      assert_equal "true", icon_node["aria-hidden"]
      badge = items[index].css("[aria-label]").find { |node| node.name != "a" }
      if count
        assert_equal count, badge["aria-label"]
        assert_equal count.to_i.to_s, badge.text.strip
      else
        assert_nil badge
      end
    end
  end

  def assert_text_heading_id(section, anchor)
    wrapper = css_select("[id='#{anchor}']").first
    assert wrapper
    assert_equal section.recordable.title, wrapper.at_css("h2").text
    assert_includes wrapper["class"], "scroll-mt-24"
    refute_includes wrapper["class"], "fp-section-title"
  end

  def assert_section_title_id(title, anchor)
    heading = css_select(".fp-section-title").find { |node| node.at_css("h2")&.text == title }
    assert_equal anchor, heading["id"]
  end

  def heading_id(section)
    RecordingStudioPresskits.section_anchor_id(section)
  end

  def long_anchor(section)
    RecordingStudioPresskits.section_anchor_id(section)
  end

  def menu_links(nav)
    nav.css("a")
  end

  def menu_params(layout, counts, icons, items)
    { layout: layout, show_counts: counts, show_icons: icons, items: items }
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_text(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: title
    )
  end

  def add_images(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Images",
      actor: @user,
      title: title
    )
  end

  def add_list(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::ListSection",
      actor: @user,
      title: title
    )
  end

  def add_menu(kit)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::MenuSection",
      actor: @user
    )
  end

  def menu_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(RecordingStudioPresskits::MenuSection)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def attach_image!(parent, filename)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: filename,
      content_type: "image/jpeg"
    )
    parent.record_attachment_upload(
      signed_blob_id: blob.signed_id,
      actor: @user,
      name: File.basename(filename, ".*")
    )
  end

  def cover_fixture_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
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
