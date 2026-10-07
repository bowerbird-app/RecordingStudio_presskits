# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class CreditsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "credits-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Credits Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "workspace credits keep their usual role when a kit overrides it" do
    tom = create_credit("Tom Ross", usual_role: "Photography", url: "https://example.com/tom")
    kit = record_kit("Spring launch")
    other = record_kit("Autumn recap")
    spring = credits_content(add_credits_section(kit, "Project credits"))
    autumn = credits_content(add_credits_section(other, "Credits"))

    spring_line = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: spring,
      credit_recording: tom,
      actor: @user
    )
    autumn_line = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: autumn,
      credit_recording: tom,
      role: "Creative Direction",
      actor: @user
    )
    again = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: spring,
      credit_recording: tom,
      role: "Film",
      actor: @user
    )

    assert_equal "Photography", spring_line.recordable.role
    assert_equal "Creative Direction", autumn_line.recordable.role
    assert_equal tom.id, spring_line.recordable.credit_recording_id
    assert_equal tom.id, autumn_line.recordable.credit_recording_id
    assert_equal tom.id, again.recordable.credit_recording_id
    workspace_toms = RecordingStudioPresskits::Credits.active_for_root(@root).select do |recording|
      recording.recordable.name == "Tom Ross"
    end
    assert_equal [tom.id], workspace_toms.map(&:id)

    RecordingStudioPresskits::Credits.revise!(
      credit_recording: tom,
      root_recording: @root,
      name: "Tom Ross",
      url: "https://example.com/tom",
      usual_role: "Photographer"
    )

    assert_equal "Photographer", tom.reload.recordable.usual_role
    assert_equal "Photography", spring_line.reload.recordable.role
    assert_equal "Creative Direction", autumn_line.reload.recordable.role
    assert_equal "https://example.com/tom", tom.recordable.url
    refute_includes spring_line.recordable.attributes.values, "Tom Ross"
  end

  test "trashing a credit hides it and restoring it shows the same line" do
    tom = create_credit("Tom Ross", usual_role: "Photography", url: nil)
    content = credits_content(add_credits_section(record_kit("Spring launch"), "Project credits"))
    line = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: content,
      credit_recording: tom,
      actor: @user
    )

    RecordingStudioPresskits::Credits.trash!(tom, actor: @user)

    assert tom.reload.trashed_at.present?
    assert_nil line.reload.trashed_at
    assert_empty RecordingStudioPresskits::Credits.active_for_root(@root)
    assert_equal [line.id], RecordingStudioPresskits::Credits.lines_for(content).map(&:id)
    assert_empty RecordingStudioPresskits::Credits.visible_lines(content)
    assert_equal(
      { role: "Photography", credit_id: tom.id },
      RecordingStudioPresskits::Api::CreditLinePayload.for(line)
    )

    RecordingStudioPresskits::Credits.restore!(tom, actor: @user)

    assert_nil tom.reload.trashed_at
    assert_equal [line], RecordingStudioPresskits::Credits.visible_lines(content)
    assert_equal(
      { role: "Photography", credit_id: tom.id, name: "Tom Ross" },
      RecordingStudioPresskits::Api::CreditLinePayload.for(line)
    )
  end

  test "removing a line leaves the credit and reordering stays on the section" do
    studio = create_credit("Studio Bright", usual_role: "Architecture", url: "https://studiobright.com.au")
    flack = create_credit("Flack Studio", usual_role: "Interior Design", url: nil)
    content = credits_content(add_credits_section(record_kit("Spring launch"), "Project credits"))
    first = RecordingStudioPresskits::Credits.add!(credits_section_recording: content, credit_recording: studio, actor: @user)
    second = RecordingStudioPresskits::Credits.add!(credits_section_recording: content, credit_recording: flack, actor: @user)

    content.recording_studio_orderable_move!(second, to_index: 0, actor: @user)

    assert_equal [second.id, first.id], RecordingStudioPresskits::Credits.lines_for(content).map(&:id)

    RecordingStudioPresskits::Credits.remove!(second, actor: @user)

    assert second.reload.trashed_at.present?
    assert_nil flack.reload.trashed_at
    assert_equal [first.id], RecordingStudioPresskits::Credits.visible_lines(content).map(&:id)
    assert_includes RecordingStudioPresskits::Credits.active_for_root(@root), flack
  end

  test "a credit from another workspace cannot be added" do
    other_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"))
    outsider = RecordingStudioPresskits::Credits.create!(
      root_recording: other_root,
      name: "Outsider",
      usual_role: "PR",
      actor: @user
    )
    content = credits_content(add_credits_section(record_kit("Spring launch"), "Project credits"))

    assert_raises(ArgumentError) do
      RecordingStudioPresskits::Credits.add!(
        credits_section_recording: content,
        credit_recording: outsider,
        actor: @user
      )
    end
    assert_empty RecordingStudioPresskits::Credits.lines_for(content)
    assert_nil RecordingStudioPresskits::Credits.find_for_root(@root, outsider.id)
  end

  test "api add copies the usual role and remove leaves the credit" do
    tom = create_credit("Tom Ross", usual_role: "Photography", url: "https://example.com/tom")
    section = add_credits_section(record_kit("Spring launch"), "Project credits")
    content = credits_content(section)

    line = RecordingStudioPresskits::Api::AddCredit.call(action_context(content, params: { credit_id: tom.id }))

    assert_equal "Photography", line.recordable.role
    assert_equal(
      {
        role: "Photography",
        credit_id: tom.id,
        name: "Tom Ross",
        url: "https://example.com/tom"
      },
      RecordingStudioPresskits::Api::CreditLinePayload.for(line)
    )
    assert_equal(
      {
        title: "Project credits",
        subtitle: nil,
        content_type: "RecordingStudioPresskits::CreditsSection",
        content_id: content.id
      },
      RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    )

    RecordingStudioPresskits::Api::RemoveCredit.call(action_context(line, params: {}))

    assert line.reload.trashed_at.present?
    assert_nil tom.reload.trashed_at
  end

  test "credits screens create, edit, add, reorder, and publish a section" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "a[href='#{recording_studio_presskits.credits_path}']", text: "Credits"

    get recording_studio_presskits.credits_path
    assert_response :success
    assert_select "h1", text: "Credits"
    assert_rounded_default_layout

    empty_kit = record_kit("Empty credits")
    post recording_studio_presskits.press_kit_sections_path(empty_kit),
         params: { type: "RecordingStudioPresskits::CreditsSection" }
    empty_section = RecordingStudioPresskits::KitQuery.sections_for(empty_kit).first
    follow_redirect!
    empty_add = recording_studio_presskits.new_press_kit_section_credit_path(empty_kit, empty_section)
    assert_select "a[href='#{empty_add}']", text: "Add credit"
    assert_select "input[name='credit_id']", count: 0
    assert_select "input[name='role']", count: 0

    get empty_add
    assert_response :success
    assert_select "h1", text: "Add credit"
    assert_select "h2", text: "Create a credit"
    assert_select "h2", text: "Choose a credit", count: 0
    assert_select "input[name='credit_id']", count: 0
    assert_select "input[name='credit[name]']"
    assert_select "label", text: "Role on this kit", count: 1
    assert_select "button", text: "Create and add"

    assert_no_difference -> { RecordingStudioPresskits::Credit.count } do
      post recording_studio_presskits.credits_path, params: { credit: { name: "  ", usual_role: "PR" } }
    end
    assert_response :unprocessable_entity

    post recording_studio_presskits.credits_path, params: {
      credit: { name: "Tom Ross", usual_role: "Photography", url: "https://example.com/tom" }
    }
    tom = RecordingStudioPresskits::Credits.active_for_root(@root).first
    assert_redirected_to recording_studio_presskits.edit_credit_path(tom)
    follow_redirect!
    assert_select "input[name='credit[name]'][value='Tom Ross']"
    assert_select "input[name='credit[usual_role]'][value='Photography']"

    patch recording_studio_presskits.credit_path(tom), params: {
      credit: { name: "Tom Ross", usual_role: "Photographer", url: "https://example.com/tom" }
    }
    assert_equal "Photographer", tom.reload.recordable.usual_role

    kit = record_kit("Spring launch")
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::CreditsSection" }
    section = RecordingStudioPresskits::KitQuery.sections_for(kit).first
    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Credits"
    assert_select "input[name='kit_section[title]']"
    assert_select "input[name='kit_section[subtitle]']"
    assert_select "input[name='credit_id']", count: 0
    assert_select "input[name='role']", count: 0
    add_credit = recording_studio_presskits.new_press_kit_section_credit_path(kit, section)
    assert_select "a[href='#{add_credit}']", text: "Add credit"

    get add_credit
    assert_response :success
    assert_select "h2", text: "Choose a credit"
    assert_select "h2", text: "Create a credit"
    assert_select "input[name='credit_id']"
    assert_select "label", text: "Role on this kit", count: 2
    assert_select "div[hidden][data-recording-studio-presskits--add-credit-target='chosen']"
    assert_select "button", text: "Add to this kit"
    assert_select "button", text: "Create and add"
    payload = JSON.parse(css_select("[data-controller='recording-studio-presskits--add-credit']").first[
      "data-recording-studio-presskits--add-credit-credits-value"
    ])
    assert_equal [{ "id" => tom.id, "name" => "Tom Ross", "usual_role" => "Photographer" }], payload

    post recording_studio_presskits.press_kit_section_credits_path(kit, section), params: {}
    assert_redirected_to add_credit
    assert_equal "Pick a credit, or add a new one.", flash[:alert]

    post recording_studio_presskits.press_kit_section_credits_path(kit, section), params: { credit_id: tom.id }
    line = RecordingStudioPresskits::Credits.lines_for(credits_content(section)).first
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_credit_path(kit, section, line)
    assert_equal "Photographer", line.recordable.role
    follow_redirect!
    assert_select "label", text: "Role on this kit"
    assert_select "input[name='credit_line[role]'][value='Photographer']"

    patch recording_studio_presskits.press_kit_section_credit_path(kit, section, line), params: {
      credit_line: { role: "Photography" }
    }
    assert_equal "Photography", line.reload.recordable.role
    assert_equal "Photographer", tom.reload.recordable.usual_role

    post recording_studio_presskits.press_kit_section_credits_path(kit, section), params: {
      credit: { name: "Studio Bright", usual_role: "Architecture", url: "https://studiobright.com.au" },
      role: "Architecture"
    }
    studio_line = RecordingStudioPresskits::Credits.lines_for(credits_content(section)).last
    assert_equal "Studio Bright", RecordingStudioPresskits::Credits.credit_for(studio_line).recordable.name
    assert_equal "Architecture", studio_line.recordable.role

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section), params: {
      recording_id: studio_line.id,
      before_recording_id: line.id
    }
    follow_redirect!
    assert_equal(
      [studio_line.id, line.id],
      RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)
    )
    assert_includes response.body, "Architecture"
    assert_includes response.body, "Studio Bright"
    assert_includes response.body, "https://studiobright.com.au"

    publish_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-credits"
    assert_response :success
    assert_blank_public_layout
    assert_operator response.body.index("Architecture"), :<, response.body.index("Studio Bright")
    assert_includes response.body, "https://studiobright.com.au"
    assert_includes response.body, "Photography"
    assert_includes response.body, "Tom Ross"

    delete recording_studio_presskits.press_kit_section_credit_path(kit, section, studio_line)
    follow_redirect!
    assert studio_line.reload.trashed_at.present?
    assert_includes RecordingStudioPresskits::Credits.active_for_root(@root).map { |credit| credit.recordable.name },
                    "Studio Bright"
    assert_select "#presskits-credit-list", text: /Studio Bright/, count: 0
    assert_select "#presskits-section-preview", text: /Studio Bright/, count: 0

    delete recording_studio_presskits.credit_path(tom)
    assert_redirected_to recording_studio_presskits.credits_path
    assert tom.reload.trashed_at.present?
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-credits"
    refute_includes response.body, "Tom Ross"
    assert_nil line.reload.trashed_at
  end

  test "another workspace cannot open this credit" do
    tom = create_credit("Tom Ross", usual_role: "Photography", url: nil)
    other_workspace = Workspace.create!(name: "Elsewhere #{SecureRandom.hex(4)}")
    other_root = RecordingStudio.root_recording_for(other_workspace)
    RecordingStudioAccessible.bootstrap_owner_access!(recording: other_root, actor: @user)
    sign_in @user
    switch_to_root(other_root)

    get recording_studio_presskits.edit_credit_path(tom)
    assert_response :not_found

    outsider = RecordingStudioPresskits::Credits.create!(
      root_recording: other_root,
      name: "Outsider",
      usual_role: "PR",
      actor: @user
    )
    switch_to_root(@root)
    kit = record_kit("Spring launch")
    section = add_credits_section(kit, "Project credits")
    post recording_studio_presskits.press_kit_section_credits_path(kit, section), params: { credit_id: outsider.id }
    assert_response :not_found
    assert_empty RecordingStudioPresskits::Credits.lines_for(credits_content(section))
  end

  private

  def create_credit(name, usual_role:, url:)
    RecordingStudioPresskits::Credits.create!(
      root_recording: @root,
      name: name,
      usual_role: usual_role,
      url: url,
      actor: @user
    )
  end

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_credits_section(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::CreditsSection",
      actor: @user,
      title: title
    )
  end

  def credits_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def action_context(recording, params:)
    ActionContext.new(
      recording: recording,
      access_grant: AccessGrant.new(actor: @user),
      params: params
    )
  end

  class AccessGrant
    def initialize(actor:)
      @actor = actor
    end

    attr_reader :actor

    def authorize!(recording:, role:)
      return if RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: role)

      raise ArgumentError, "API access grant is not authorized for this capability"
    end
  end

  class ActionContext
    def initialize(recording:, access_grant:, params:)
      @recording = recording
      @access_grant = access_grant
      @params = params
    end

    attr_reader :recording, :access_grant, :params
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-credits", status: "published", meta_robots: "index,follow" }
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
end
