# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ListSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "list-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "List Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "create section stores the heading and no items" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::ListSection.count }, 1 do
        assert_no_difference -> { RecordingStudioPresskits::ListItem.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::ListSection",
            actor: @user,
            title: "At a glance",
            subtitle: "The short version"
          )
        end
      end
    end

    content = section_content(@section)
    assert_equal "At a glance", @section.recordable.title
    assert_equal "The short version", @section.recordable.subtitle
    assert_equal @section, content.parent_recording
    assert_kind_of RecordingStudioPresskits::ListSection, content.recordable
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "At a glance",
        subtitle: "The short version",
        content_type: "RecordingStudioPresskits::ListSection",
        content_id: content.id,
        items: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "a kit can hold two list sections with their own items" do
    kit = record_kit("Spring launch")
    first = add_list_section(kit, title: "At a glance")
    second = add_list_section(kit, title: "The room")
    record_item(section_content(first), key: "Capacity", value: "120 seats", icon: "star")
    record_item(section_content(second), key: "Floor", value: "Oak")

    assert_equal [first.id, second.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal 1, RecordingStudioPresskits::ListSection.active_items(section_content(first)).size
    assert_equal 1, RecordingStudioPresskits::ListSection.active_items(section_content(second)).size
  end

  test "the editor adds edits reorders and trashes items" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::ListSection.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::ListSection" }
    end
    follow_redirect!
    assert_response :success
    section = list_section(kit)
    assert_equal "List", section.recordable.title
    assert_select ".fp-section-title h2", text: "List"
    assert_select "#presskits-section-placeholder", text: /Add a line/

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "h1", text: "List"
    assert_select "#presskits-list-editor.flat-pack-collection-editor, #presskits-list-editor .flat-pack-collection-editor"
    assert_includes response.body, "--collection-editor-columns: auto 7rem minmax(0, 1fr) minmax(0, 1.4fr) auto"
    assert_select ".flat-pack-collection-editor-header span", text: "Icon"
    assert_select ".flat-pack-collection-editor-header span", text: "Key"
    assert_select ".flat-pack-collection-editor-header span", text: "Value"
    assert_select "[data-flat-pack--collection-editor-target='addButton']", text: "Item"
    assert_select "#presskits-list-lines-save button", text: "Save"
    assert_select "[data-flat-pack--list-orderable-param-uuid-name-value='moving_recording_id']"
    assert_select "[data-flat-pack--list-orderable-param-target-position-name-value='target_position']"
    assert_includes response.body, "No lines yet"
    refute_select "#presskits-section-actions a", text: "Item"
    refute_section_preview_card

    assert_no_difference -> { RecordingStudioPresskits::ListItem.count } do
      patch recording_studio_presskits.press_kit_section_list_lines_path(kit, section), params: {
        list_lines: { lines_attributes: { "0" => { icon: "star", key: "", value: "120 seats" } } }
      }
    end
    assert_response :unprocessable_entity
    assert_select "li.is-invalid"

    assert_no_difference -> { RecordingStudioPresskits::ListItem.count } do
      patch recording_studio_presskits.press_kit_section_list_lines_path(kit, section), params: {
        list_lines: { lines_attributes: { "0" => { icon: "not-a-real-icon", key: "Capacity", value: "120 seats" } } }
      }
    end
    assert_response :unprocessable_entity

    assert_difference -> { RecordingStudioPresskits::ListItem.count }, 2 do
      patch recording_studio_presskits.press_kit_section_list_lines_path(kit, section), params: {
        list_lines: {
          lines_attributes: {
            "0" => { icon: "", key: "Capacity", value: "120 seats", decoy: "nope" },
            "1" => { icon: "search", key: "Find", value: "Us" }
          }
        }
      }
    end
    follow_redirect!
    assert_response :success
    first = live_items(section).first
    second = live_items(section).last
    assert_nil first.recordable.icon
    assert_equal "Capacity", first.recordable.key
    assert_equal "120 seats", first.recordable.value
    refute_includes first.recordable.attributes.values, "nope"
    assert_equal "magnifying-glass", second.recordable.icon

    previous = first.recordable
    patch recording_studio_presskits.press_kit_section_list_lines_path(kit, section), params: {
      list_lines: {
        lines_attributes: {
          "0" => { id: first.id, icon: "star", key: "Capacity", value: "140 seats" },
          "1" => { id: second.id, icon: "magnifying-glass", key: "Find", value: "Us" }
        }
      }
    }
    assert_equal "star", first.reload.recordable.icon
    assert_equal "140 seats", first.recordable.value
    refute_equal previous.id, first.recordable.id

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "At a glance", subtitle: "The short version" }
    }
    follow_redirect!
    assert_equal "At a glance", section.reload.recordable.title

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    preview = css_select("#presskits-editor-preview").first
    assert_select preview, ".fp-section-title h2", text: "At a glance"
    assert_list_table(preview)

    patch recording_studio_presskits.press_kit_section_list_item_order_path(kit, section), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!
    assert_equal [second.id, first.id], live_items(section).map(&:id)

    patch recording_studio_presskits.press_kit_section_list_item_order_path(kit, section),
          params: { moving_recording_id: first.id, target_position: 1 },
          as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["ok"]
    assert_equal [first.id, second.id], live_items(section).map(&:id)

    patch recording_studio_presskits.press_kit_section_list_lines_path(kit, section), params: {
      list_lines: {
        lines_attributes: {
          "0" => { id: second.id, icon: "magnifying-glass", key: "Find", value: "Us", _destroy: "1" },
          "1" => { id: first.id, icon: "star", key: "Capacity", value: "140 seats" }
        }
      }
    }
    follow_redirect!
    assert second.reload.trashed_at.present?
    assert_nil first.reload.trashed_at
    assert_nil section.reload.trashed_at
    refute_includes response.body, "Find"
    assert_includes response.body, "Capacity"
  end

  test "the item screen still saves one line" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_list_section(kit, title: "At a glance")

    get recording_studio_presskits.new_press_kit_section_list_item_path(kit, section)
    assert_response :success
    assert_select "select[name='list_item[icon]'] option[value='star']"
    assert_select "input[name='list_item[key]']"
    assert_select "input[name='list_item[value]']"

    assert_difference -> { RecordingStudioPresskits::ListItem.count }, 1 do
      post recording_studio_presskits.press_kit_section_list_items_path(kit, section), params: {
        list_item: { icon: "star", key: "Capacity", value: "120 seats" }
      }
    end
    follow_redirect!
    assert_equal "star", live_items(section).first.recordable.icon
  end

  test "the public page shows the icon key and value and hides an empty list" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_list_section(kit, title: "At a glance")
    content = section_content(section)
    record_item(content, key: "Capacity", value: "120 seats", icon: "star")
    record_item(content, key: "Floor", value: "Oak")
    publish_list_kit!(kit)

    get "/published/#{kit.publishable_child_recording.id}/spring-launch-list"
    assert_response :success
    assert_select ".fp-section-title h2", text: "At a glance"
    assert_list_table(response.body)

    empty = add_list_section(kit, title: "Empty list")
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "#presskits-section-#{empty.id} #presskits-section-placeholder"
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-list"
    assert_select ".fp-section-title h2", text: "At a glance"
    refute_includes response.body, "Empty list"
  end

  test "duplicating a kit copies items icon and order" do
    kit = record_kit("Spring launch")
    section = add_list_section(kit, title: "At a glance")
    content = section_content(section)
    first = record_item(content, key: "Capacity", value: "120 seats", icon: "star")
    second = record_item(content, key: "Floor", value: "Oak")
    content.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )

    copy = kit.duplicate_in_place!(actor: @user)
    copied_section = RecordingStudioPresskits::KitQuery.sections_for(copy).first
    copied_items = RecordingStudioPresskits::ListSection.active_items(section_content(copied_section))

    assert_equal "At a glance (Copy)", copied_section.recordable.title
    assert_equal ["Floor", "Capacity"], copied_items.map { |child| child.recordable.key }
    assert_nil copied_items.first.recordable.icon
    assert_equal "star", copied_items.last.recordable.icon
    refute_includes copied_items.map(&:id), first.id
  end

  test "trashing a section leaves the rows and leaves the kit" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_list_section(kit, title: "At a glance")
    item = record_item(section_content(section), key: "Capacity", value: "120 seats", icon: "star")

    delete recording_studio_presskits.press_kit_section_path(kit, section)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert_nil kit.reload.trashed_at
    assert item.reload.persisted?
    assert_empty RecordingStudioPresskits::KitQuery.sections_for(kit)

    section.recording_studio_trashable_restore!(actor: @user)
    assert_nil section.reload.trashed_at
    assert_nil item.reload.trashed_at
    assert_equal [section.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal [item.id], live_items(section).map(&:id)
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_list_section(kit, title: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::ListSection",
      actor: @user,
      title: title
    )
  end

  def record_item(content, key:, value:, icon: nil)
    content.record(RecordingStudioPresskits::ListItem, parent_recording: content, actor: @user) do |item|
      item.icon = icon
      item.key = key
      item.value = value
    end
  end

  def list_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(RecordingStudioPresskits::ListSection)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def live_items(section)
    RecordingStudioPresskits::ListSection.active_items(section_content(section))
  end

  def publish_list_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-list", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
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

  def refute_section_preview_card
    refute_select "#presskits-section-preview"
  end

  def assert_list_table(scope)
    html = scope.is_a?(String) ? scope : scope.to_html
    assert_includes html, "max-w-[65ch]"
    assert_match(/\[&(?:amp;)?_thead\]:hidden/, html)
    root = scope.is_a?(String) ? nil : scope
    if root
      assert_select root, "[data-list-item]", count: 2
      assert_select root, "[data-list-item] [data-flat-pack--icon-name-value='star']", count: 1
      assert_select root, "[data-list-item] [data-flat-pack--icon-name-value='magnifying-glass']", count: 1
      assert_select root, "td .truncate.whitespace-nowrap", text: "Capacity"
      assert_select root, "td .truncate.whitespace-nowrap", text: "140 seats"
      assert_includes html, "whitespace-nowrap"
    else
      assert_select "[data-list-item]", count: 2
      assert_select "[data-list-item] [data-flat-pack--icon-name-value='star']", count: 1
      assert_select "td .truncate.whitespace-nowrap", text: "Capacity"
      assert_select "td .truncate.whitespace-nowrap", text: "120 seats"
      assert_select "td .truncate.whitespace-nowrap", text: "Floor"
      assert_select "td .truncate.whitespace-nowrap", text: "Oak"
      assert_includes html, "whitespace-nowrap"
    end
  end
end
