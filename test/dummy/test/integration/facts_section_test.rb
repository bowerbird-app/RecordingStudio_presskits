# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FactsSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "facts-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Facts Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "create section stores the heading and default display settings" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::FactsSection.count }, 1 do
        assert_no_difference -> { RecordingStudioPresskits::Fact.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::FactsSection",
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
    assert_kind_of RecordingStudioPresskits::FactsSection, content.recordable
    assert_equal "list", content.recordable.display_style
    assert_equal 3, content.recordable.columns
    assert_equal [content.id], @section.child_recordings.map(&:id)
    assert_equal(
      {
        title: "Company statistics",
        subtitle: "This year",
        content_type: "RecordingStudioPresskits::FactsSection",
        content_id: content.id,
        display: { style: "list", columns: 3 },
        facts: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "a kit can hold two facts sections with their own facts and layouts" do
    kit = record_kit("Spring launch")
    cards = add_facts_section(kit, title: "Company statistics")
    list = add_facts_section(kit, title: "Project specifications")
    cards_content = section_content(cards)
    list_content = section_content(list)
    record_fact(cards_content, label: "Projects", value: "120")
    record_fact(cards_content, label: "Employees", value: "85")
    record_fact(list_content, label: "Floor area", value: "420", unit: "m²")
    @root.revise(cards_content, actor: @user) do |recordable|
      recordable.display_style = "cards"
      recordable.columns = 3
    end

    assert_equal [cards.id, list.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal "cards", cards_content.reload.recordable.display_style
    assert_equal "list", list_content.recordable.display_style
    assert_equal 2, RecordingStudioPresskits::FactsSection.active_facts(cards_content).size
    assert_equal 1, RecordingStudioPresskits::FactsSection.active_facts(list_content).size
  end

  test "the editor adds edits reorders and trashes facts and saves display settings" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    assert_difference -> { RecordingStudioPresskits::FactsSection.count }, 1 do
      post recording_studio_presskits.press_kit_sections_path(kit),
           params: { type: "RecordingStudioPresskits::FactsSection" }
    end
    follow_redirect!
    assert_response :success
    section = facts_section(kit)
    new_fact = recording_studio_presskits.new_press_kit_section_fact_path(kit, section)
    assert_equal "Facts & Figures", section.recordable.title
    assert_select ".fp-section-title h2", text: "Facts & Figures"
    assert_select "#presskits-section-placeholder"

    get recording_studio_presskits.heading_press_kit_section_path(kit, section)
    assert_select "input[name='kit_section[title]'][placeholder=?]", "Facts & Figures"
    assert_select "input[name='kit_section[subtitle]']"

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "h1", text: "Facts & Figures"
    refute_select "input[name='kit_section[title]']"
    assert_select "#presskits-section-actions a[href='#{new_fact}']", text: "Fact"
    assert_select "[data-flat-pack--icon-name-value='plus']"
    assert_select "select[name='facts_section[display_style]'], [name='facts_section[display_style]']"
    assert_includes response.body, "No figures yet"
    refute_section_preview_card

    get new_fact
    assert_response :success
    assert_select "input[name='fact[label]']"
    assert_select "input[name='fact[value]']"
    assert_select "input[name='fact[unit]']"
    assert_select "textarea[name='fact[description]']"
    assert_select "input[name='fact[source_url]']"
    assert_select "input[name='fact[as_of_date]']"

    assert_no_difference -> { RecordingStudioPresskits::Fact.count } do
      post recording_studio_presskits.press_kit_section_facts_path(kit, section), params: {
        fact: { label: "", value: "120" }
      }
    end
    assert_response :unprocessable_entity

    assert_difference -> { RecordingStudioPresskits::Fact.count }, 1 do
      post recording_studio_presskits.press_kit_section_facts_path(kit, section), params: {
        fact: { label: "Projects", value: "120", unit: "", description: "Shipped work", decoy: "nope" }
      }
    end
    follow_redirect!
    assert_response :success
    first = live_facts(section).first
    assert_equal "Projects", first.recordable.label
    assert_equal "120", first.recordable.value
    refute_includes first.recordable.attributes.values, "nope"

    post recording_studio_presskits.press_kit_section_facts_path(kit, section), params: {
      fact: { label: "Employees", value: "85" }
    }
    second = live_facts(section).last
    patch recording_studio_presskits.press_kit_section_fact_path(kit, section, second), params: {
      fact: { label: "Employees", value: "90", unit: "people" }
    }
    assert_equal "90 people", second.reload.recordable.formatted_value

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      kit_section: { title: "Company statistics", subtitle: "This year" }
    }
    follow_redirect!
    assert_equal "Company statistics", section.reload.recordable.title

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      facts_section: { display_style: "cards", columns: 4 }
    }
    follow_redirect!
    content = section_content(section)
    assert_equal "cards", content.reload.recordable.display_style
    assert_equal 4, content.recordable.columns

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select ".fp-section-title h2", text: "Company statistics"
    assert_includes css_select("#presskits-editor-preview").first.to_html, "grid-cols-4"
    assert_includes response.body, "Projects"
    assert_includes response.body, "120"
    assert_includes response.body, "Employees"

    patch recording_studio_presskits.press_kit_section_fact_order_path(kit, section), params: {
      recording_id: second.id,
      before_recording_id: first.id
    }
    follow_redirect!
    assert_equal [second.id, first.id], live_facts(section).map(&:id)

    delete recording_studio_presskits.press_kit_section_fact_path(kit, section, second)
    follow_redirect!
    assert second.reload.trashed_at.present?
    assert_nil first.reload.trashed_at
    assert_nil section.reload.trashed_at
    refute_includes response.body, "Employees"
    assert_includes response.body, "Projects"

    second.recording_studio_trashable_restore!(actor: @user)
    assert_nil second.reload.trashed_at
  end

  test "list cards and table render and an empty section stays off the public page" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_facts_section(kit, title: "Project specifications")
    content = section_content(section)
    record_fact(content, label: "Floor area", value: "420", unit: "m²", description: "Total internal floor area")
    record_fact(content, label: "Completion", value: "2025")
    publish_facts_kit!(kit)

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    preview = css_select("#presskits-editor-preview").first
    assert_select preview, "dt", text: "Floor area"
    assert_select preview, "dd", text: "420 m²"
    refute_includes preview.at_css("dd").text, "420  m²"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      facts_section: { display_style: "cards", columns: 2 }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_path(kit)
    preview = css_select("#presskits-editor-preview").first.to_html
    assert_includes preview, "grid-cols-2"
    assert_includes preview, "420 m²"
    assert_includes preview, "Floor area"

    patch recording_studio_presskits.press_kit_section_path(kit, section), params: {
      facts_section: { display_style: "table", columns: 3 }
    }
    follow_redirect!
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "#presskits-editor-preview th", text: "Fact"
    assert_select "#presskits-editor-preview th", text: "Value"
    assert_select "#presskits-editor-preview td", text: "Floor area"
    assert_select "#presskits-editor-preview td", text: "420 m²"

    get "/published/#{kit.publishable_child_recording.id}/spring-launch-facts"
    assert_response :success
    assert_select ".fp-section-title h2", text: "Project specifications"
    assert_select "th", text: "Fact"
    assert_select "td", text: "420 m²"

    empty = add_facts_section(kit)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-section-#{empty.id} #presskits-section-placeholder"
    get recording_studio_presskits.edit_press_kit_section_path(kit, empty)
    refute_section_preview_card
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-facts"
    assert_select "table", count: 1
    assert_select "table tbody tr", count: 2
  end

  test "duplicating a kit copies facts display settings and order" do
    kit = record_kit("Spring launch")
    section = add_facts_section(kit, title: "Company statistics")
    content = section_content(section)
    first = record_fact(content, label: "Projects", value: "120")
    second = record_fact(content, label: "Countries", value: "15")
    @root.revise(content, actor: @user) do |recordable|
      recordable.display_style = "cards"
      recordable.columns = 4
    end
    content.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second.id, first.id],
      actor: @user
    )

    copy = kit.duplicate_in_place!(actor: @user)
    copied_section = RecordingStudioPresskits::KitQuery.sections_for(copy).first
    copied_content = section_content(copied_section)
    copied_facts = RecordingStudioPresskits::FactsSection.active_facts(copied_content)

    assert_equal "Company statistics (Copy)", copied_section.recordable.title
    assert_equal "cards", copied_content.recordable.display_style
    assert_equal 4, copied_content.recordable.columns
    assert_equal ["Countries", "Projects"], copied_facts.map { |child| child.recordable.label }
    refute_includes copied_facts.map(&:id), first.id
    refute_includes copied_facts.map(&:id), second.id
  end

  test "trashing a section leaves the kit and trashing a fact leaves the section" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_facts_section(kit, title: "Company statistics")
    content = section_content(section)
    fact = record_fact(content, label: "Projects", value: "120")

    delete recording_studio_presskits.press_kit_section_fact_path(kit, section, fact)
    assert fact.reload.trashed_at.present?
    assert_nil section.reload.trashed_at

    fact.recording_studio_trashable_restore!(actor: @user)
    delete recording_studio_presskits.press_kit_section_path(kit, section)
    assert_redirected_to recording_studio_presskits.edit_press_kit_path(kit)
    assert section.reload.trashed_at.present?
    assert_nil kit.reload.trashed_at
  end

  test "a published payload keeps public access rules and omits trashed facts" do
    kit = record_kit("Spring launch")
    section = add_facts_section(kit, title: "Company statistics")
    content = section_content(section)
    record_fact(content, label: "Projects", value: "120")
    gone = record_fact(content, label: "Gone", value: "0")
    gone.recording_studio_trashable_trash!(actor: @user)
    @root.revise(content, actor: @user) do |recordable|
      recordable.display_style = "cards"
      recordable.columns = 3
    end

    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    assert_equal ["Projects"], payload.fetch(:facts).map { |entry| entry[:label] }
    assert_equal({ style: "cards", columns: 3 }, payload[:display])

    get "/published/#{kit.publishable_child_recording&.id}/spring-launch-facts"
    assert_response :not_found

    publish_facts_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-facts"
    assert_response :success
    assert_includes response.body, "Projects"
    refute_includes response.body, "Gone"
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_facts_section(kit, title: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::FactsSection",
      actor: @user,
      title: title
    )
  end

  def record_fact(content, label:, value:, unit: nil, description: nil)
    content.record(RecordingStudioPresskits::Fact, parent_recording: content, actor: @user) do |fact|
      fact.label = label
      fact.value = value
      fact.unit = unit
      fact.description = description
    end
  end

  def facts_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      section_content(section)&.recordable.is_a?(RecordingStudioPresskits::FactsSection)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def live_facts(section)
    RecordingStudioPresskits::FactsSection.active_facts(section_content(section))
  end

  def publish_facts_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-facts", status: "published", meta_robots: "index,follow" }
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
end
