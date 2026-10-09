# frozen_string_literal: true

require "test_helper"

class SectionApiActionsTest < ActiveSupport::TestCase
  test "create section records a kit section and its text child" do
    root, kit = kit_tree
    user = owner_for(root)

    section = RecordingStudioPresskits::Api::CreateSection.call(action_context(kit, user, params: {
      content_type: "RecordingStudioPresskits::Text",
      title: "Launch notes",
      subtitle: "Doors at noon"
    }))

    content = RecordingStudioPresskits::KitQuery.section_content(section)
    assert_equal kit.id, section.parent_recording_id
    assert_equal "Launch notes", section.recordable.title
    assert_equal "Doors at noon", section.recordable.subtitle
    assert_equal "RecordingStudioPresskits::Text", content.recordable_type
    assert_equal RecordingStudioPresskits::Text.opening_body, content.recordable.body
  end

  test "create section refuses an unknown content type" do
    root, kit = kit_tree
    user = owner_for(root)

    error = assert_no_section_change(kit) do
      RecordingStudioPresskits::Api::CreateSection.call(action_context(kit, user, params: { content_type: "Nope" }))
    end

    assert_match(/not a press kit section content type/, error.message)
  end

  test "create section refuses an actor without edit" do
    root, kit = kit_tree
    owner_for(root)

    error = assert_no_section_change(kit) do
      RecordingStudioPresskits::Api::CreateSection.call(action_context(kit, stranger, params: {
        content_type: "RecordingStudioPresskits::Text"
      }))
    end

    assert_equal "API access grant is not authorized for this capability", error.message
  end

  test "reorder sections changes kit section order only" do
    root, kit = kit_tree
    user = owner_for(root)
    first = add_text(kit, user, "First")
    second = add_text(kit, user, "Second")

    RecordingStudioPresskits::Api::ReorderSections.call(action_context(kit, user, params: {
      ordered_recording_ids: [second.id, first.id]
    }))

    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    assert_equal kit.id, first.reload.parent_recording_id
  end

  test "reorder sections refuses a missing id list" do
    root, kit = kit_tree
    user = owner_for(root)
    add_text(kit, user, "First")

    error = assert_raises(ArgumentError) do
      RecordingStudioPresskits::Api::ReorderSections.call(action_context(kit, user, params: { ordered_recording_ids: [] }))
    end

    assert_equal "ordered_recording_ids is required", error.message
  end

  test "reorder sections refuses an actor without edit" do
    root, kit = kit_tree
    user = owner_for(root)
    add_text(kit, user, "First")

    error = assert_raises(ArgumentError) do
      RecordingStudioPresskits::Api::ReorderSections.call(action_context(kit, stranger, params: {
        ordered_recording_ids: []
      }))
    end

    assert_equal "API access grant is not authorized for this capability", error.message
  end

  test "remove section trashes the kit section and its content" do
    root, kit = kit_tree
    user = owner_for(root)
    section = add_text(kit, user, "Launch notes")
    content = RecordingStudioPresskits::KitQuery.section_content(section)

    removed = RecordingStudioPresskits::Api::RemoveSection.call(action_context(section, user, params: {}))

    assert_equal section.id, removed.id
    assert removed.trashed_at.present?
    assert_equal true, removed.trash_root
    assert content.reload.trashed_at.present?
    assert_equal false, content.trash_root
    assert_nil kit.reload.trashed_at
    assert_empty RecordingStudioPresskits::KitQuery.sections_for(kit)
  end

  test "video section api registers videos without replacing the video type" do
    registry = fake_api_registry
    registry.register_recordable_type_api(
      "RecordingStudioVideo::Video",
      marker: :video_gem,
      output_keys: %i[title url description provider canonical_url content_type]
    )

    with_recording_studio_api(registry) do
      RecordingStudioPresskits::Api.register!
    end

    video = registry.types.fetch("RecordingStudioVideo::Video")
    assert_equal :video_gem, video[:marker]
    assert_equal %i[title url description provider canonical_url content_type], video[:output_keys]

    registered = registry.types.fetch("RecordingStudioPresskits::VideoSection")
    assert_equal %i[index show], registered[:operations]
    assert_equal %i[videos], registered[:output_keys]

    kit_section = registry.types.fetch("RecordingStudioPresskits::KitSection")
    assert_includes kit_section[:output_keys], :title
    assert_includes kit_section[:output_keys], :videos
  end

  test "section actions register once against orderable and trashable" do
    registry = fake_api_registry
    with_recording_studio_api(registry) do
      RecordingStudioPresskits::Api.register!
      RecordingStudioPresskits::Api.register!
    end

    assert_equal :orderable, registry.actions[:create_section][:capability]
    assert_equal RecordingStudioPresskits::Api::CreateSection, registry.actions[:create_section][:handler]
    assert_equal :orderable, registry.actions[:reorder_sections][:capability]
    assert_equal :trashable, registry.actions[:remove_section][:capability]
    assert_equal %i[create_section reorder_sections], registry.types.fetch("RecordingStudioPresskits::PressKit")[:capability_actions]
    assert_equal %i[remove_section], registry.types.fetch("RecordingStudioPresskits::KitSection")[:capability_actions]
    assert_equal %i[show update], registry.types.fetch("RecordingStudioPresskits::PressKit")[:operations]
    assert_equal %i[title description cover_style cover_color],
                 registry.types.fetch("RecordingStudioPresskits::PressKit")[:output_keys]
    assert_equal %i[cover_style cover_color],
                 registry.types.fetch("RecordingStudioPresskits::PressKit")[:writable_attributes]
    assert_equal %i[index show update], registry.types.fetch("RecordingStudioPresskits::KitSection")[:operations]
  end

  test "remove section refuses an actor without edit" do
    root, kit = kit_tree
    user = owner_for(root)
    section = add_text(kit, user, "Launch notes")

    error = assert_raises(ArgumentError) do
      RecordingStudioPresskits::Api::RemoveSection.call(action_context(section, stranger, params: {}))
    end

    assert_equal "API access grant is not authorized for this capability", error.message
    assert_nil section.reload.trashed_at
    assert_nil kit.reload.trashed_at
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Api #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "section-api-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = user
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root_recording, actor: user)
    raise result.error if result.failure?

    user
  ensure
    Current.actor = previous
  end

  def stranger
    User.create!(
      email: "stranger-api-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def add_text(kit, user, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: user,
      title: title
    )
  end

  def action_context(recording, actor, params:)
    ActionContext.new(recording: recording, access_grant: AccessGrant.new(actor: actor), params: params)
  end

  def with_recording_studio_api(registry)
    raise "Recording Studio API is already loaded" if defined?(::RecordingStudioApi)

    Object.const_set(:RecordingStudioApi, registry)
    yield
  ensure
    Object.send(:remove_const, :RecordingStudioApi) if defined?(::RecordingStudioApi)
  end

  def fake_api_registry
    Class.new do
      def actions
        @actions ||= {}
      end

      def types
        @types ||= {}
      end

      def capability_action(name)
        actions[name.to_sym]
      end

      def register_capability_action(name, **registration)
        actions[name.to_sym] = registration
      end

      def register_recordable_type_api(type_name, **registration)
        types[type_name] = registration
      end
    end.new
  end

  def assert_no_section_change(kit)
    error = nil
    assert_no_difference -> { RecordingStudioPresskits::KitSection.count } do
      error = assert_raises(ArgumentError) { yield }
    end
    assert_empty RecordingStudioPresskits::KitQuery.sections_for(kit)
    error
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
end
