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

  test "two kits keep independent copies of the same name" do
    kit = record_kit("Spring launch")
    other = record_kit("Autumn recap")
    spring = credits_content(add_credits_section(kit, "Project credits"))
    autumn = credits_content(add_credits_section(other, "Credits"))

    spring_line = add_line(spring, name: "Tom Ross", role: "Photography", url: "https://example.com/tom")
    autumn_line = add_line(autumn, name: "Tom Ross", role: "Creative Direction", url: "https://example.com/tom")

    assert_nil spring_line.recordable.credit_recording_id
    assert_nil autumn_line.recordable.credit_recording_id
    refute_equal spring_line.recordable.id, autumn_line.recordable.id

    RecordingStudioPresskits::Credits.revise_line!(
      line_recording: spring_line,
      root_recording: @root,
      name: "Thomas Ross",
      url: "https://example.com/thomas",
      role: "Photography"
    )

    assert_equal "Thomas Ross", spring_line.reload.recordable.name
    assert_equal "Tom Ross", autumn_line.reload.recordable.name
    assert_equal "https://example.com/tom", autumn_line.recordable.url
  end

  test "api add stores name url and role and remove trashes the line" do
    section = add_credits_section(record_kit("Spring launch"), "Project credits")
    content = credits_content(section)

    line = RecordingStudioPresskits::Api::AddCredit.call(
      action_context(content, params: { name: "Tom Ross", url: "https://example.com/tom", role: "Photography" })
    )

    assert_equal "Photography", line.recordable.role
    assert_equal "Tom Ross", line.recordable.name
    assert_equal(
      { name: "Tom Ross", role: "Photography", url: "https://example.com/tom" },
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

    error = assert_raises(ArgumentError) do
      RecordingStudioPresskits::Api::AddCredit.call(action_context(content, params: { name: "  " }))
    end
    assert_equal "Give them a name.", error.message

    RecordingStudioPresskits::Api::RemoveCredit.call(action_context(line, params: {}))

    assert line.reload.trashed_at.present?
  end

  test "credits editor saves name role and url rows and publishes them" do
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "a[data-flat-pack-sidebar-item='true'] span.fp-sidebar-label", text: "Credits", count: 0
    assert_select "a[data-flat-pack-sidebar-item='true'] span.fp-sidebar-label", text: "Images"

    kit = record_kit("Spring launch")
    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::CreditsSection" }
    section = RecordingStudioPresskits::KitQuery.sections_for(kit).first
    follow_redirect!
    assert_equal "Credits", section.recordable.title

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_response :success
    assert_select "#presskits-credit-lines"
    assert_select ".flat-pack-collection-editor-empty", text: "No credits yet"
    assert_select "button[data-flat-pack--collection-editor-target='addButton']", text: "Credit"
    assert_select "template label", text: "Name"
    assert_select "template label", text: "Role"
    assert_select "template label", text: "URL"
    assert_select "template label", text: "Default role", count: 0
    assert_select "[data-search-url]", count: 0
    assert_select "[data-create-url]", count: 0
    assert_select "script[data-credit-catalog]", count: 0
    lines_form = css_select("#presskits-credit-lines").first
    assert_includes lines_form["data-controller"], "flat-pack--unsaved-changes"
    assert_includes lines_form["data-controller"], "recording-studio-presskits--credit-preview"
    assert_select "#presskits-credit-lines[data-action*='input->recording-studio-presskits--credit-preview#fields']"
    assert_select "#presskits-credit-lines[data-action*='click->recording-studio-presskits--credit-preview#drop']"
    assert_select "#presskits-credit-lines[data-action*='click->recording-studio-presskits--credit-preview#note']"
    save = css_select("#presskits-credit-lines-save button[type=submit]").first
    assert_equal "Save", save.text.squish
    assert_equal "default", save["data-fp-style"]
    assert_equal "submit", save["data-flat-pack--unsaved-changes-target"]
    order = recording_studio_presskits.press_kit_section_credit_order_path(kit, section)
    assert_select "[data-flat-pack--list-orderable-orderable-url-value='#{order}']"
    assert_select "[data-flat-pack--list-orderable-param-uuid-name-value='moving_recording_id']"
    assert_select "[data-flat-pack--list-orderable-param-target-position-name-value='target_position']"

    save_lines(kit, section, { "0" => { name: "  ", role: "Ghost", url: "" } })
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_empty RecordingStudioPresskits::Credits.lines_for(credits_content(section))

    save_lines(kit, section, {
      "0" => { name: "Tom Ross", role: "Photography", url: "https://example.com/tom" },
      "1" => { name: "Studio Bright", role: "Architecture", url: "https://studiobright.com.au" }
    })
    lines = RecordingStudioPresskits::Credits.lines_for(credits_content(section))
    tom = lines[0]
    studio = lines[1]
    assert_equal "Tom Ross", tom.recordable.name
    assert_equal "Photography", tom.recordable.role
    assert_equal "https://example.com/tom", tom.recordable.url
    assert_equal "Studio Bright", studio.recordable.name
    follow_redirect!
    assert_select "input[name='credit_lines[credit_lines_attributes][0][name]'][value='Tom Ross']"
    assert_select "input[name='credit_lines[credit_lines_attributes][0][role]'][value='Photography']"
    assert_select "input[name='credit_lines[credit_lines_attributes][0][url]'][value='https://example.com/tom']"

    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_select "#presskits-editor-preview [data-credit-line-id='#{tom.id}']"
    assert_select "#presskits-editor-preview [data-credit-role]", text: "Photography"
    assert_select "#presskits-editor-preview [data-credit-name]", text: "Tom Ross"
    assert_select "#presskits-editor-preview a[href='https://example.com/tom']", text: "Tom Ross"

    save_lines(kit, section, {
      "0" => { id: tom.id, name: "", role: "Photography", url: "https://example.com/tom", _destroy: "0" }
    })
    assert_equal "Give each credit a name.", flash[:alert]
    assert_equal "Tom Ross", tom.reload.recordable.name

    save_lines(kit, section, {
      "0" => { id: tom.id, name: "Tom Ross", role: "Film", url: "https://example.com/tom", _destroy: "0" },
      "1" => { id: studio.id, name: "Studio Bright", role: "Architecture", url: "https://studiobright.com.au", _destroy: "1" }
    })
    assert studio.reload.trashed_at.present?
    assert_equal "Film", tom.reload.recordable.role
    assert_equal [tom.id], RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)

    save_lines(kit, section, {
      "0" => { id: tom.id, name: "Tom Ross", role: "Photography", url: "https://example.com/tom", _destroy: "0" },
      "1" => { name: "Studio Bright", role: "Architecture", url: "https://studiobright.com.au" }
    })
    studio = RecordingStudioPresskits::Credits.lines_for(credits_content(section)).last

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section), params: {
      recording_id: studio.id,
      before_recording_id: tom.id
    }
    follow_redirect!
    assert_equal(
      [studio.id, tom.id],
      RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)
    )
    assert_includes response.body, "Studio Bright"
    assert_includes response.body, "https://studiobright.com.au"

    patch recording_studio_presskits.press_kit_section_credit_order_path(kit, section),
          params: { moving_recording_id: tom.id, target_position: 1 },
          as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["ok"]
    assert_equal [tom.id, studio.id], RecordingStudioPresskits::Credits.lines_for(credits_content(section)).map(&:id)

    publish_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-credits"
    assert_response :success
    assert_blank_public_layout
    assert_includes response.body, "Photography"
    assert_includes response.body, "Tom Ross"
    assert_includes response.body, "https://example.com/tom"
    assert_includes response.body, "Architecture"
    assert_includes response.body, "Studio Bright"
  end

  test "duplicating a kit copies credit lines that can change on their own" do
    kit = record_kit("Spring launch")
    content = credits_content(add_credits_section(kit, "Project credits"))
    line = add_line(content, name: "Tom Ross", role: "Photography", url: "https://example.com/tom")

    duplicate = kit.duplicate_in_place!(actor: @user)
    copied_section = duplicate.child_recordings.find { |child| child.recordable.is_a?(RecordingStudioPresskits::KitSection) }
    copied_content = RecordingStudioPresskits::KitQuery.section_content(copied_section)
    copied = RecordingStudioPresskits::Credits.visible_lines(copied_content).first

    refute_equal line.id, copied.id
    assert_equal "Tom Ross (Copy)", copied.recordable.name
    assert_equal "Photography", copied.recordable.role
    assert_equal "https://example.com/tom", copied.recordable.url

    RecordingStudioPresskits::Credits.revise_line!(
      line_recording: copied,
      root_recording: @root,
      name: "Tom Copy",
      url: "https://example.com/copy",
      role: "Film"
    )

    assert_equal "Tom Ross", line.reload.recordable.name
    assert_equal "Photography", line.recordable.role
    assert_equal "https://example.com/tom", line.recordable.url
    assert_equal "Tom Copy", copied.reload.recordable.name
  end

  test "migration copies a shared credit onto each kit and a rerun does not add lines" do
    tom = create_credit("Tom Ross", url: "https://example.com/tom")
    spring = credits_content(add_credits_section(record_kit("Spring launch"), "Project credits"))
    autumn = credits_content(add_credits_section(record_kit("Autumn recap"), "Credits"))
    spring_line = legacy_line(spring, tom, role: "Photography")
    autumn_line = legacy_line(autumn, tom, role: "Creative Direction")
    before = RecordingStudioPresskits::CreditLine.count

    RecordingStudioPresskits::CreditLineOwnership.migrate!

    assert_equal before, RecordingStudioPresskits::CreditLine.count
    assert_equal "Tom Ross", spring_line.reload.recordable.name
    assert_equal "https://example.com/tom", spring_line.recordable.url
    assert_equal "Photography", spring_line.recordable.role
    assert_equal "Tom Ross", autumn_line.reload.recordable.name
    assert_equal tom.id, spring_line.recordable.credit_recording_id
    assert_equal tom.id, autumn_line.recordable.credit_recording_id
    assert_equal "Tom Ross", tom.reload.recordable.name

    RecordingStudioPresskits::CreditLineOwnership.migrate!
    assert_equal before, RecordingStudioPresskits::CreditLine.count
    assert_equal "Tom Ross", spring_line.reload.recordable.name

    RecordingStudioPresskits::Credits.revise_line!(
      line_recording: spring_line,
      root_recording: @root,
      name: "Thomas Ross",
      url: "https://example.com/thomas",
      role: "Photography"
    )

    assert_equal "Tom Ross", autumn_line.reload.recordable.name
    assert_equal "Tom Ross", tom.reload.recordable.name
    assert_equal "Thomas Ross", spring_line.reload.recordable.name
  end

  test "migration names a missing credit from the role and hides a trashed credit" do
    missing = legacy_line(
      credits_content(add_credits_section(record_kit("Spring launch"), "Project credits")),
      nil,
      role: "Ghost"
    )
    RecordingStudioPresskits::CreditLine.where(id: missing.recordable.id).update_all(credit_recording_id: SecureRandom.uuid)

    blank = legacy_line(
      credits_content(add_credits_section(record_kit("Blank role"), "Credits")),
      nil,
      role: nil
    )
    RecordingStudioPresskits::CreditLine.where(id: blank.recordable.id).update_all(
      credit_recording_id: SecureRandom.uuid,
      role: nil
    )

    tom = create_credit("Tom Ross", url: "https://example.com/tom")
    RecordingStudioPresskits::Credits.trash!(tom, actor: @user)
    hidden = legacy_line(
      credits_content(add_credits_section(record_kit("Hidden"), "Credits")),
      tom,
      role: "Photography"
    )

    RecordingStudioPresskits::CreditLineOwnership.migrate!

    assert_equal "Ghost", missing.reload.recordable.name
    assert_nil missing.trashed_at
    assert_equal "Credit", blank.reload.recordable.name
    assert_equal "Tom Ross", hidden.reload.recordable.name
    assert_equal "https://example.com/tom", hidden.recordable.url
    assert hidden.trashed_at.present?
    assert_empty RecordingStudioPresskits::Credits.visible_lines(hidden.parent_recording)
  end

  test "down restores a line hidden for a trashed credit" do
    tom = create_credit("Tom Ross", url: "https://example.com/tom")
    RecordingStudioPresskits::Credits.trash!(tom, actor: @user)
    line = legacy_line(
      credits_content(add_credits_section(record_kit("Hidden"), "Credits")),
      tom,
      role: "Photography"
    )
    owned = add_line(
      credits_content(add_credits_section(record_kit("Owned"), "Credits")),
      name: "Studio Bright",
      role: "Architecture",
      url: nil
    )
    RecordingStudioPresskits::CreditLineOwnership.migrate!
    assert line.reload.trashed_at.present?

    migration_class.new.down

    assert_nil line.reload.trashed_at
    assert_nil RecordingStudio::Recording.find_by(id: owned.id)
    refute ActiveRecord::Base.connection.column_exists?(:recording_studio_credit_lines, :name)
    assert_equal false, RecordingStudioPresskits::CreditLine.columns_hash["credit_recording_id"].null
  ensure
    migration_class.new.up
    RecordingStudioPresskits::CreditLine.reset_column_information
  end

  private

  def migration_class
    require Rails.root.join("db/migrate/20261012130000_copy_credit_names_onto_lines").to_s
    ::CopyCreditNamesOntoLines
  end

  def create_credit(name, url:)
    RecordingStudioPresskits::Credits.create!(
      root_recording: @root,
      name: name,
      url: url,
      actor: @user
    )
  end

  def add_line(section_recording, name:, role:, url:)
    RecordingStudioPresskits::Credits.add!(
      credits_section_recording: section_recording,
      name: name,
      role: role,
      url: url,
      actor: @user
    )
  end

  def legacy_line(section_recording, credit_recording, role:)
    line = add_line(section_recording, name: "Placeholder", role: role, url: "https://example.com/old")
    RecordingStudioPresskits::CreditLine.where(id: line.recordable.id).update_all(
      name: nil,
      url: nil,
      credit_recording_id: credit_recording&.id
    )
    line
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
