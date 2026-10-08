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
    assert_select "#presskits-credit-lines"
    assert_select ".flat-pack-collection-editor-empty", text: "No credits yet"
    assert_select "button[data-flat-pack--collection-editor-target='addButton']", text: "Credit"
    assert_select "a", text: "Add credit", count: 0
    assert_select "input[name='credit_id']", count: 0
    assert_select "template input[data-create-field='name'][data-fill-from-query]"
    assert_select "template input[data-create-field='usual_role']"
    assert_select "template label", text: "Default role"
    assert_select "template label", text: "Usual role", count: 0
    assert_select "template input[data-create-field='url'][form='collection-editor-unattached']"
    search_url = recording_studio_presskits.search_credits_path
    assert_select "[data-search-url='#{search_url}']"
    assert_select "[data-create-url='#{recording_studio_presskits.credits_path}']"
    empty_order = recording_studio_presskits.press_kit_section_credit_order_path(empty_kit, empty_section)
    assert_select "[data-flat-pack--list-orderable-orderable-url-value='#{empty_order}']"
    assert_select "[data-flat-pack--list-orderable-param-uuid-name-value='moving_recording_id']"
    assert_select "[data-flat-pack--list-orderable-param-target-position-name-value='target_position']"
    heading = css_select("form[action='#{recording_studio_presskits.press_kit_section_path(empty_kit, empty_section)}']").first
    assert_equal "flat-pack--unsaved-changes", heading["data-controller"]
    refute_includes heading.inner_html, "credit_lines"
    lines_form = css_select("#presskits-credit-lines").first
    assert_includes lines_form["data-controller"], "flat-pack--unsaved-changes"
    assert_includes lines_form["data-controller"], "recording-studio-presskits--credit-preview"
    empty_save = css_select("#presskits-credit-lines-save button[type=submit]").first
    assert_equal "Save", empty_save.text.squish
    assert_equal "default", empty_save["data-fp-style"]
    assert_equal "submit", empty_save["data-flat-pack--unsaved-changes-target"]
    assert_operator lines_form.inner_html.index("flat-pack-collection-editor"), :<,
                    lines_form.inner_html.index('id="presskits-credit-lines-save"')
    assert_select "#presskits-section-preview [data-credit-lines]", count: 0
    assert_select "#presskits-credit-lines[data-action*='collection-editor:selected->recording-studio-presskits--credit-preview#choose']"
    assert_select "#presskits-credit-lines[data-action*='input->recording-studio-presskits--credit-preview#role']"
    assert_select "#presskits-credit-lines[data-action*='click->recording-studio-presskits--credit-preview#drop']"
    assert_equal({}, JSON.parse(css_select("script[data-credit-catalog]").first.text))

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
    form = css_select("form[action='#{recording_studio_presskits.press_kit_section_path(kit, section)}']").first
    assert_equal "flat-pack--unsaved-changes", form["data-controller"]
    update = css_select("#presskits-section-update button[type=submit]").first
    assert_equal "Update", update.text.squish
    assert_equal "default", update["data-fp-style"]
    assert_select "input[name='credit_id']", count: 0
    assert_select "a", text: "Add credit", count: 0
    save = css_select("#presskits-credit-lines-save button[type=submit]").first
    assert_equal "Save", save.text.squish
    assert_equal "default", save["data-fp-style"]
    assert_equal "submit", save["data-flat-pack--unsaved-changes-target"]
    spring_lines = css_select("#presskits-credit-lines").first
    assert_operator spring_lines.inner_html.index("flat-pack-collection-editor"), :<,
                    spring_lines.inner_html.index('id="presskits-credit-lines-save"')

    get recording_studio_presskits.search_credits_path, params: { q: "tom" }, as: :json
    assert_response :success
    assert_equal(
      [{ "id" => tom.id, "title" => "Tom Ross", "description" => "Photographer" }],
      JSON.parse(response.body)["items"]
    )
    get recording_studio_presskits.search_credits_path, params: { q: " " }, as: :json
    assert_empty JSON.parse(response.body)["items"]

    assert_no_difference -> { RecordingStudioPresskits::Credits.active_for_root(@root).count } do
      post recording_studio_presskits.credits_path, params: { name: "  ", usual_role: "PR" }, as: :json
    end
    assert_response :unprocessable_entity
    assert_equal false, JSON.parse(response.body)["ok"]
    assert_includes JSON.parse(response.body)["errors"], "Give them a name."

    save_lines(kit, section, { "9" => { credit_recording_id: "", role: "Ghost" } })
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_empty RecordingStudioPresskits::Credits.lines_for(credits_content(section))

    save_lines(kit, section, { "0" => { credit_recording_id: tom.id, role: "" } })
    line = RecordingStudioPresskits::Credits.lines_for(credits_content(section)).first
    assert_equal "Photographer", line.recordable.role
    follow_redirect!
    assert_select "[data-collection-editor-title]", text: "Tom Ross"
    assert_select "input[name='credit_lines[credit_lines_attributes][0][role]'][value='Photographer']"
    assert_select "#presskits-credit-lines[data-controller*='recording-studio-presskits--credit-preview'][data-controller*='flat-pack--unsaved-changes']"
    assert_select "#presskits-section-preview [data-credit-line-id='#{line.id}']"
    assert_select "#presskits-section-preview [data-credit-role]", text: "Photographer"
    assert_select "#presskits-section-preview [data-credit-name]", text: "Tom Ross"
    assert_equal "https://example.com/tom", JSON.parse(css_select("script[data-credit-catalog]").first.text)[tom.id]

    save_lines(kit, section, {
      "0" => { id: line.id, credit_recording_id: tom.id, role: "Photography", _destroy: "0" }
    })
    assert_equal "Photography", line.reload.recordable.role
    assert_equal "Photographer", tom.reload.recordable.usual_role

    patch recording_studio_presskits.credit_path(tom), params: {
      credit: { name: "Tom Ross", usual_role: "Still photographer", url: "https://example.com/tom" }
    }
    assert_equal "Photography", line.reload.recordable.role
    patch recording_studio_presskits.credit_path(tom), params: {
      credit: { name: "Tom Ross", usual_role: "Photographer", url: "https://example.com/tom" }
    }

    post recording_studio_presskits.credits_path,
         params: { name: "Studio Bright", usual_role: "Architecture", url: "https://studiobright.com.au" },
         as: :json
    assert_response :success
    created = JSON.parse(response.body)
    assert_equal true, created["ok"]
    assert_equal "Studio Bright", created.dig("item", "title")
    studio = RecordingStudioPresskits::Credits.find_for_root(@root, created.dig("item", "id"))

    save_lines(kit, section, {
      "0" => { id: line.id, role: "Photography", _destroy: "0" },
      "1" => { credit_recording_id: studio.id, role: "Architecture" },
      "2" => { credit_recording_id: tom.id, role: "Film" }
    })
    lines = RecordingStudioPresskits::Credits.lines_for(credits_content(section))
    studio_line = lines[1]
    film_line = lines[2]
    assert_equal "Studio Bright", RecordingStudioPresskits::Credits.credit_for(studio_line).recordable.name
    assert_equal "Architecture", studio_line.recordable.role
    assert_equal "Film", film_line.recordable.role
    assert_equal tom.id, RecordingStudioPresskits::Credits.credit_for(film_line).id

    save_lines(kit, section, {
      "0" => { id: line.id, role: "Photography", _destroy: "0" },
      "1" => { id: studio_line.id, role: "Architecture", _destroy: "0" },
      "2" => { id: SecureRandom.uuid, role: "Nope", _destroy: "0" },
      "3" => { id: film_line.id, role: "Film", _destroy: "1" }
    })
    assert film_line.reload.trashed_at.present?
    assert_nil tom.reload.trashed_at
    assert_equal(
      [line.id, studio_line.id],
      RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)
    )

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
    catalog = JSON.parse(css_select("script[data-credit-catalog]").first.text)
    assert_equal "https://studiobright.com.au", catalog[studio.id]
    assert_equal "https://example.com/tom", catalog[tom.id]

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section),
          params: { moving_recording_id: line.id, target_position: 1 },
          as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["ok"]
    assert_equal [line.id, studio_line.id], RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section),
          params: { moving_recording_id: studio_line.id, target_position: 1 },
          as: :json
    assert_equal(
      [studio_line.id, line.id],
      RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)
    )

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section), params: {}, as: :json
    assert_response :unprocessable_entity
    assert_equal false, JSON.parse(response.body)["ok"]

    publish_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-credits"
    assert_response :success
    assert_blank_public_layout
    assert_operator response.body.index("Architecture"), :<, response.body.index("Studio Bright")
    assert_includes response.body, "https://studiobright.com.au"
    assert_includes response.body, "Photography"
    assert_includes response.body, "Tom Ross"

    save_lines(kit, section, {
      "0" => { id: studio_line.id, role: "Architecture", _destroy: "1" },
      "1" => { id: line.id, role: "Photography", _destroy: "0" }
    })
    follow_redirect!
    assert studio_line.reload.trashed_at.present?
    assert_includes RecordingStudioPresskits::Credits.active_for_root(@root).map { |credit| credit.recordable.name },
                    "Studio Bright"
    assert_select "[data-collection-editor-title]", text: "Studio Bright", count: 0
    assert_select "#presskits-section-preview", text: /Studio Bright/, count: 0

    delete recording_studio_presskits.credit_path(tom)
    assert_redirected_to recording_studio_presskits.credits_path
    assert tom.reload.trashed_at.present?
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-credits"
    refute_includes response.body, "Tom Ross"
    assert_nil line.reload.trashed_at

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_select "[data-collection-editor-title]", text: "In the trash"
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

    save_lines(kit, section, { "0" => { credit_recording_id: outsider.id, role: "PR" } })
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_equal "That credit is not in this workspace.", flash[:alert]
    assert_empty RecordingStudioPresskits::Credits.lines_for(credits_content(section))

    get recording_studio_presskits.search_credits_path, params: { q: "Outsider" }, as: :json
    assert_empty JSON.parse(response.body)["items"]
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

  def save_lines(kit, section, rows)
    patch recording_studio_presskits.press_kit_section_credit_lines_path(kit, section),
          params: { credit_lines: { credit_lines_attributes: rows } }
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
