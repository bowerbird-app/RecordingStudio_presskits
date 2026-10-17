# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

require_relative "support/presskits_api_mirror"

class ListItemPayloadTest < ActiveSupport::TestCase
  include PresskitsApiMirror

  test "includes icon key and value and keeps a blank icon as nil" do
    item = RecordingStudioPresskits::ListItem.new(icon: "  ", key: "Capacity", value: "120 seats")

    assert_equal(
      { icon: nil, key: "Capacity", value: "120 seats" },
      RecordingStudioPresskits::Api::ListPayload.for(item)
    )
  end

  test "accepts a flatpack icon name and rejects an unknown one" do
    item = RecordingStudioPresskits::ListItem.new(icon: "star", key: "Capacity", value: "120 seats")
    assert item.valid?
    assert_equal "star", item.icon

    aliased = RecordingStudioPresskits::ListItem.new(icon: "search", key: "Find", value: "Us")
    assert aliased.valid?
    assert_equal "magnifying-glass", aliased.icon

    blank = RecordingStudioPresskits::ListItem.new(icon: "", key: "Capacity", value: "120 seats")
    assert blank.valid?
    assert_nil blank.icon

    missing = RecordingStudioPresskits::ListItem.new(icon: "star", key: "  ", value: "")
    refute missing.valid?
    assert_includes missing.errors[:key], "can't be blank"
    assert_includes missing.errors[:value], "can't be blank"

    unknown = RecordingStudioPresskits::ListItem.new(icon: "not-a-real-icon", key: "Capacity", value: "120 seats")
    refute unknown.valid?
    assert_includes unknown.errors[:icon], "is not a Flatpack icon"
    assert_includes RecordingStudioPresskits::Icons.names, "star"
    refute_includes RecordingStudioPresskits::Icons.names, "not-a-real-icon"
  end

  test "section payload lists active items in order and omits a trashed item" do
    built = sections_with_items
    section = built.fetch(:section)
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    items = payload.fetch(:items)

    assert_equal "At a glance", payload[:title]
    assert_equal "The short version", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::ListSection", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    keys = items.map { |entry| entry[:key] }
    assert_equal %w[Capacity Opened], keys
    assert_equal %i[icon key value], items.first.keys
    assert_equal "star", items.first[:icon]
    assert_nil items.last[:icon]
    refute_includes keys, "Gone"
    refute_includes items.first.values, "star: Capacity"
  end

  test "list section api serializer returns items and an empty section returns an empty list" do
    built = sections_with_items
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    item_registration = registry.types.fetch("RecordingStudioPresskits::ListItem")
    item = built.fetch(:first)
    withheld = { icon: nil, key: nil, value: nil }

    assert_equal payload.fetch(:items), RecordingStudioPresskits::Api::ListPayload.for_recording(content)
    assert_equal %i[icon key value], item_registration.fetch(:output_keys)
    RecordingStudioPresskits::Embargo.stub(:withhold_protected?, true) do
      assert_equal withheld, item_registration.fetch(:serializer).call(item.recordable, context: Object.new)
      assert_equal withheld, RecordingStudioPresskits::Api::ListPayload.for(item.recordable, context: Object.new)
    end
    assert_equal %i[create destroy index show update], item_registration.fetch(:operations).sort
    refute registry.types.fetch("RecordingStudioPresskits::ListSection").key?(:output_keys)
    refute registry.types.fetch("RecordingStudioPresskits::ListSection").key?(:serializer)
  end

  test "an empty list section serializes items as an empty array" do
    root, kit = kit_tree
    user = owner_for(root)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::ListSection",
      actor: user,
      title: "At a glance"
    )

    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    assert_equal [], payload.fetch(:items)
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "List payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "list-payload-#{SecureRandom.hex(4)}@example.com",
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

  def sections_with_items
    root, kit = kit_tree
    user = owner_for(root)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::ListSection",
      actor: user,
      title: "At a glance",
      subtitle: "The short version"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    first = record_item(content, icon: "star", key: "Capacity", value: "120 seats")
    record_item(content, key: "Opened", value: "2024")
    gone = record_item(content, key: "Gone", value: "0")
    gone.recording_studio_trashable_trash!(actor: user)
    { section: section, content: content, first: first }
  end

  def record_item(content, key:, value:, icon: nil)
    content.record(RecordingStudioPresskits::ListItem, parent_recording: content) do |item|
      item.icon = icon
      item.key = key
      item.value = value
    end
  end

  def fake_api_registry
    Class.new do
      def types
        @types ||= {}
      end

      def register_recordable_type_api(type_name, **registration)
        types[type_name] = registration
      end

      def capability_action(name)
        capability_actions[name.to_sym]
      end

      def register_capability_action(name, **registration)
        capability_actions[name.to_sym] = registration
      end

      def capability_actions
        @capability_actions ||= {}
      end
    end.new
  end
end
