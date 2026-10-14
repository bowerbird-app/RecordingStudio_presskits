# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class StatsSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "stats-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Stats Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "create section stores the heading" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::StatsSection.count }, 1 do
        assert_no_difference -> { RecordingStudioPresskits::Stat.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::StatsSection",
            actor: @user,
            title: "Company statistics",
            subtitle: "This year"
          )
        end
      end
    end

    content = section_content(@section)
    assert_equal "Company statistics", @section.recordable.title
    assert_equal "This year", @section.recordable.subtitle
    assert_equal @section, content.parent_recording
    assert_kind_of RecordingStudioPresskits::StatsSection, content.recordable
    refute content.recordable.respond_to?(:display_style)
    refute content.recordable.respond_to?(:columns)
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "Company statistics",
        subtitle: "This year",
        content_type: "RecordingStudioPresskits::StatsSection",
        content_id: content.id,
        stats: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "a kit can hold two stats sections with their own stats" do
    kit = record_kit("Spring launch")
    wide = add_stats_section(kit, title: "Company statistics")
    narrow = add_stats_section(kit, title: "Project specifications")
    wide_content = section_content(wide)
    narrow_content = section_content(narrow)
    record_stat(wide_content, label: "Projects", value: "120")
    record_stat(wide_content, label: "Employees", value: "85")
    record_stat(narrow_content, label: "Floor area", value: "420", unit: "m²")

    assert_equal [wide.id, narrow.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    refute wide_content.reload.recordable.respond_to?(:columns)
    refute narrow_content.reload.recordable.respond_to?(:columns)
    assert_equal 2, RecordingStudioPresskits::StatsSection.active_stats(wide_content).size
    assert_equal 1, RecordingStudioPresskits::StatsSection.active_stats(narrow_content).size
  end

  test "the editor adds edits reorders and trashes stats" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::StatsSection.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::StatsSection" }
    end
    follow_redirect!
    assert_response :success
    section = stats_section(kit)
    new_stat = recording_studio_presskits.new_press_kit_section_stat_path(kit, section)
    assert_equal "Stats", section.recordable.title
    assert_select ".fp-section-title h2", text: "Stats"
    assert_select "#presskits-section-placeholder"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Stats"
    assert_select "input[name='kit_section[subtitle]']"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "h1", text: "Stats"
    refute_select "input[name='kit_section[title]']"
    assert_select "#presskits-section-actions a[href='#{new_stat}']", text: "Stat"
    assert_select "[data-flat-pack--icon-name-value='plus']"
    refute_select "[name='stats_section[columns]']"
    refute_select "form#presskits-stats-columns-form"
    refute_select "[name='stats_section[display_style]']"
    refute_includes response.body, "facts-display"
    refute_includes response.body, "Show as"
    assert_includes response.body, "No stats yet"
    refute_section_preview_card

    get new_stat
    assert_response :success
    assert_select "input[name='stat[value]'][required]"
    assert_select "input[name='stat[unit]']"
    assert_select "input[name='stat[label]'][required]"
    assert_select "textarea[name='stat[description]']"
    refute_select "input[name='stat[source_url]']"
    refute_select "input[name='stat[as_of_date]']"
    refute_includes response.body, "More detail"
    assert_operator response.body.index("name=\"stat[value]\""), :<, response.body.index("name=\"stat[unit]\"")
    assert_operator response.body.index("name=\"stat[unit]\""), :<, response.body.index("name=\"stat[label]\"")
    assert_operator response.body.index("name=\"stat[label]\""), :<, response.body.index("name=\"stat[description]\"")
    assert_operator response.body.index("name=\"stat[description]\""), :<, response.body.index("name=\"stat[icon]\"")
    assert_select "input[type=radio][name='stat[icon]'][value='chart-bar']"
    assert_select "input[type=radio][name='stat[icon]'][value='']"
    assert_select "[data-flat-pack--icon-name-value='users']"

    assert_no_difference -> { RecordingStudioPresskits::Stat.count } do
      post recording_studio_presskits.press_kit_section_stats_path(kit, section), params: {
        stat: { label: "", value: "120" }
      }
    end
    assert_response :unprocessable_entity

    assert_difference -> { RecordingStudioPresskits::Stat.count }, 1 do
      post recording_studio_presskits.press_kit_section_stats_path(kit, section), params: {
        stat: {
          label: "Projects",
          value: "120",
          unit: "",
          description: "Shipped work",
          source_url: "https://example.com",
          as_of_date: "2026-01-01",
          decoy: "nope"
        }
      }
    end
    follow_redirect!
    assert_response :success
    first = live_stats(section).first
    assert_equal "Projects", first.recordable.label
    assert_equal "120", first.recordable.value
    assert_equal "Shipped work", first.recordable.description
    assert_nil first.recordable.icon
    refute first.recordable.respond_to?(:source_url)
    refute first.recordable.respond_to?(:as_of_date)
    refute_includes first.recordable.attributes.values, "nope"

    assert_no_difference -> { RecordingStudioPresskits::Stat.count } do
      patch recording_studio_presskits.press_kit_section_stat_path(kit, section, first), params: {
        stat: { label: "Projects", value: "120", icon: "not-an-icon" }
      }
    end
    assert_response :unprocessable_entity
    assert_nil first.reload.recordable.icon

    patch recording_studio_presskits.press_kit_section_stat_path(kit, section, first), params: {
      stat: { label: "Projects", value: "120", icon: "chart-bar" }
    }
    assert_equal "chart-bar", first.reload.recordable.icon

    patch recording_studio_presskits.press_kit_section_stat_path(kit, section, first), params: {
      stat: { label: "Projects", value: "120", icon: "" }
    }
    assert_nil first.reload.recordable.icon

    post recording_studio_presskits.press_kit_section_stats_path(kit, section), params: {
      stat: { label: "Employees", value: "85" }
    }
    second = live_stats(section).last
    patch recording_studio_presskits.press_kit_section_stat_path(kit, section, second), params: {
      stat: { label: "Employees", value: "90", unit: "people" }
    }
    assert_equal "90 people", second.reload.recordable.formatted_value

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Company statistics", subtitle: "This year" }
    }
    follow_redirect!
    assert_equal "Company statistics", section.reload.recordable.title

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select ".fp-section-title h2", text: "Company statistics"
    assert_includes css_select("#presskits-editor-preview").first.to_html, "lg:grid-cols-3"
    assert_includes response.body, "Projects"
    assert_includes response.body, "120"
    assert_includes response.body, "Shipped work"
    assert_includes response.body, "Employees"
    refute_includes response.body, "As of"

    patch recording_studio_presskits.press_kit_section_stat_order_path(kit, section), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!
    assert_equal [second.id, first.id], live_stats(section).map(&:id)

    delete recording_studio_presskits.press_kit_section_stat_path(kit, section, second)
    follow_redirect!
    assert second.reload.trashed_at.present?
    assert_nil first.reload.trashed_at
    assert_nil section.reload.trashed_at
    refute_includes response.body, "Employees"
    assert_includes response.body, "Projects"

    second.recording_studio_trashable_restore!(actor: @user)
    assert_nil second.reload.trashed_at
  end

  test "cards render in three columns and an empty section stays off the public page" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    add_stats_section(kit, title: "Project specifications")
    content = section_content(stats_section(kit))
    record_stat(content, label: "Floor area", value: "420", unit: "m²", description: "Total internal floor area", icon: "building-office-2")
    record_stat(content, label: "Completion", value: "2025")
    publish_stats_kit!(kit)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    preview = css_select("#presskits-editor-preview").first.to_html
    assert_stats_grid(preview)
    assert_stat_card(preview, value: "420", unit: "m²", label: "Floor area", description: "Total internal floor area", icon: "building-office-2")
    assert_stat_card(preview, value: "2025", label: "Completion")
    refute_includes preview, "As of"
    refute_includes preview, "<th"
    refute_includes preview, "<dt"

    get "/published/#{kit.publishable_child_recording.id}/spring-launch-stats"
    assert_response :success
    assert_select ".fp-section-title h2", text: "Project specifications"
    assert_stats_grid(response.body)
    assert_stat_card(response.body, value: "420", unit: "m²", label: "Floor area", description: "Total internal floor area", icon: "building-office-2")
    assert_stat_card(response.body, value: "2025", label: "Completion")
    refute_includes response.body, "As of"
    refute_includes response.body, "<th"

    empty = add_stats_section(kit)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-section-#{empty.id} #presskits-section-placeholder"
    get recording_studio_presskits.edit_press_kit_section_path(kit, empty)
    refute_section_preview_card
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-stats"
    assert_select ".fp-section-title h2", text: "Project specifications"
    assert_select ".fp-section-title h2", text: "Stats", count: 0
  end

  test "duplicating a kit copies stat order" do
    kit = record_kit("Spring launch")
    section = add_stats_section(kit, title: "Company statistics")
    content = section_content(section)
    first = record_stat(content, label: "Projects", value: "120")
    second = record_stat(content, label: "Countries", value: "15")
    content.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )

    copy = kit.duplicate_in_place!(actor: @user)
    copied_section = RecordingStudioPresskits::KitQuery.sections_for(copy).first
    copied_content = section_content(copied_section)
    copied_stats = RecordingStudioPresskits::StatsSection.active_stats(copied_content)

    assert_equal "Company statistics (Copy)", copied_section.recordable.title
    refute copied_content.recordable.respond_to?(:columns)
    assert_equal ["Countries", "Projects"], copied_stats.map { |child| child.recordable.label }
    refute_includes copied_stats.map(&:id), first.id
    refute_includes copied_stats.map(&:id), second.id
  end

  test "trashing a section leaves the kit and trashing a stat leaves the section" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_stats_section(kit, title: "Company statistics")
    content = section_content(section)
    stat = record_stat(content, label: "Projects", value: "120")

    delete recording_studio_presskits.press_kit_section_stat_path(kit, section, stat)
    assert stat.reload.trashed_at.present?
    assert_nil section.reload.trashed_at

    stat.recording_studio_trashable_restore!(actor: @user)
    delete recording_studio_presskits.press_kit_section_path(kit, section)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert_nil kit.reload.trashed_at
  end

  test "a published payload keeps public access rules and omits trashed stats" do
    kit = record_kit("Spring launch")
    section = add_stats_section(kit, title: "Company statistics")
    content = section_content(section)
    record_stat(content, label: "Projects", value: "120")
    gone = record_stat(content, label: "Gone", value: "0")
    gone.recording_studio_trashable_trash!(actor: @user)

    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    assert_equal ["Projects"], payload.fetch(:stats).map { |entry| entry[:label] }
    refute payload.key?(:columns)
    refute payload.key?(:display)

    get "/published/#{kit.publishable_child_recording&.id}/spring-launch-stats"
    assert_response :not_found

    publish_stats_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-stats"
    assert_response :success
    assert_includes response.body, "Projects"
    refute_includes response.body, "Gone"
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_stats_section(kit, title: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::StatsSection",
      actor: @user,
      title: title
    )
  end

  def record_stat(content, label:, value:, unit: nil, description: nil, icon: nil)
    content.record(RecordingStudioPresskits::Stat, parent_recording: content, actor: @user) do |stat|
      stat.label = label
      stat.value = value
      stat.unit = unit
      stat.description = description
      stat.icon = icon
    end
  end

  def stats_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(RecordingStudioPresskits::StatsSection)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def live_stats(section)
    RecordingStudioPresskits::StatsSection.active_stats(section_content(section))
  end

  def publish_stats_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-stats", status: "published", meta_robots: "index,follow" }
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

  def assert_stats_grid(html)
    assert_includes html, "grid-cols-1"
    assert_includes html, "md:grid-cols-2"
    assert_includes html, "lg:grid-cols-3"
    refute_includes html, "lg:grid-cols-2"
    refute_includes html, "lg:grid-cols-4"
  end

  def assert_stat_card(html, value:, label:, unit: nil, description: nil, icon: nil)
    fragment = Nokogiri::HTML.fragment(html)
    card = fragment.css(".text-center").find { |node| node.at_css(".text-4xl")&.text == value }
    assert card, "expected a centered stat card for #{value}"
    icon_node = card.at_css("[data-flat-pack--icon-name-value]")
    if icon
      assert_equal icon, icon_node["data-flat-pack--icon-name-value"]
      assert_includes icon_node["class"], "w-8"
      assert_includes icon_node["class"], "h-8"
      assert_operator card.to_html.index("data-flat-pack--icon-name-value"), :<, card.to_html.index("text-4xl")
    else
      assert_nil icon_node
    end
    assert_includes card.at_css(".text-4xl")["class"], "font-bold"
    assert_includes card.at_css(".fp-tabular-nums")["class"], "fp-tabular-nums"
    assert_equal label, card.at_css(".text-lg")&.text
    assert_includes card.at_css(".text-lg")["class"], "font-semibold"

    unit_node = card.at_css(".text-xl")
    if unit
      assert_equal " #{unit}", unit_node.text
      assert_includes unit_node["class"], "font-medium"
    else
      assert_nil unit_node
    end

    description_node = card.at_css(".text-sm")
    if description
      assert_equal description, description_node.text
      assert_includes description_node["class"], "text-(--surface-muted-content-color)"
    else
      assert_nil description_node
    end
  end
end
