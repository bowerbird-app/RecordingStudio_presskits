# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class StatPayloadTest < ActiveSupport::TestCase
  test "includes every stat key and keeps blank optionals as nil" do
    stat = RecordingStudioPresskits::Stat.new(
      label: "Floor area",
      value: "420",
      unit: " m² ",
      description: " Total internal floor area ",
      source_url: "https://example.com/area",
      as_of_date: Date.new(2025, 1, 1)
    )

    assert_equal(
      {
        label: "Floor area",
        value: "420",
        unit: "m²",
        description: "Total internal floor area",
        source_url: "https://example.com/area",
        as_of_date: Date.new(2025, 1, 1)
      },
      RecordingStudioPresskits::Api::StatPayload.for(stat)
    )
  end

  test "omits blank optional fields as nil" do
    stat = RecordingStudioPresskits::Stat.new(label: "Completed", value: "2025", unit: "  ", description: nil)

    assert_equal(
      {
        label: "Completed",
        value: "2025",
        unit: nil,
        description: nil,
        source_url: nil,
        as_of_date: nil
      },
      RecordingStudioPresskits::Api::StatPayload.for(stat)
    )
  end

  test "section payload leaves a text section at four keys" do
    built = sections_with_stats
    text = built.fetch(:text)
    text_content = RecordingStudioPresskits::KitQuery.section_content(text)

    assert_equal(
      {
        title: "Notes",
        subtitle: nil,
        content_type: "RecordingStudioPresskits::Text",
        content_id: text_content.id
      },
      RecordingStudioPresskits::Api::SectionPayload.for(text.recordable, text)
    )
  end

  test "section payload lists active stats in order with the column count" do
    built = sections_with_stats
    section = built.fetch(:section)
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    stats = payload.fetch(:stats)
    labels = stats.map { |entry| entry[:label] }

    assert_equal "Project stats", payload[:title]
    assert_equal "On the books", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::StatsSection", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    assert_equal 3, payload[:columns]
    refute payload.key?(:display)
    refute payload.key?(:facts)
    assert_equal ["Floor area", "Completed"], labels
    assert_equal %i[label value unit description source_url as_of_date], stats.first.keys
    assert_equal "m²", stats.first[:unit]
    refute_includes labels, "Gone"
  end

  test "stats section api serializer returns columns and stats" do
    built = sections_with_stats
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudioPresskits::StatsSection").fetch(:serializer)
    serialized = serializer.call(content.recordable, recording: content)

    assert_equal payload.fetch(:stats), serialized.fetch(:stats)
    assert_equal payload.fetch(:columns), serialized.fetch(:columns)
    refute serialized.key?(:display)
  end

  test "stat requires label and value and accepts an http source" do
    stat = RecordingStudioPresskits::Stat.new(label: "", value: "", source_url: "ftp://example.com")

    refute stat.valid?
    assert_includes stat.errors[:label], "can't be blank"
    assert_includes stat.errors[:value], "can't be blank"
    assert_includes stat.errors[:source_url], "must be an HTTP or HTTPS link"

    stat.label = "Employees"
    stat.value = "85"
    stat.source_url = "https://example.com/team"
    assert stat.valid?
  end

  test "stats section validates columns and keeps the default" do
    section = RecordingStudioPresskits::StatsSection.new

    refute section.respond_to?(:display_style)
    assert_equal 3, section.columns
    assert section.valid?

    section.columns = 5
    refute section.valid?
    assert_includes section.errors[:columns], "is not included in the list"

    section.columns = nil
    assert section.valid?
    assert_equal 3, section.columns

    section.columns = 2
    assert section.valid?
  end

  test "formatted value joins a unit without a trailing space" do
    with_unit = RecordingStudioPresskits::Stat.new(label: "Floor area", value: "420", unit: "m²")
    without_unit = RecordingStudioPresskits::Stat.new(label: "Completed", value: "2025", unit: "  ")

    assert_equal "420 m²", with_unit.formatted_value
    assert_equal "2025", without_unit.formatted_value
  end

  test "rewrite_recordable_types renames stored fact types" do
    root, kit = kit_tree
    user = owner_for(root)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::StatsSection",
      actor: user
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    stat = record_stat(content, label: "Projects", value: "12")
    RecordingStudio::Recording.where(id: content.id).update_all(
      recordable_type: "RecordingStudioPresskits::FactsSection"
    )
    RecordingStudio::Recording.where(id: stat.id).update_all(
      recordable_type: "RecordingStudioPresskits::Fact"
    )

    load Rails.root.join("db/migrate/20261014120000_rename_recording_studio_facts_to_stats.rb")
    RenameRecordingStudioFactsToStats.rewrite_recordable_types

    assert_equal "RecordingStudioPresskits::StatsSection", content.reload.recordable_type
    assert_equal "RecordingStudioPresskits::Stat", stat.reload.recordable_type
    assert_kind_of RecordingStudioPresskits::StatsSection, content.recordable
    assert_equal 3, content.recordable.columns
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Stat payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "stat-payload-#{SecureRandom.hex(4)}@example.com",
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

  def sections_with_stats
    root, kit = kit_tree
    user = owner_for(root)
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: user,
      title: "Notes"
    )
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::StatsSection",
      actor: user,
      title: "Project stats",
      subtitle: "On the books"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    root.revise(content, actor: user) { |recordable| recordable.columns = 3 }
    content.reload
    record_stat(content, label: "Floor area", value: "420", unit: "m²")
    record_stat(content, label: "Completed", value: "2025")
    gone = record_stat(content, label: "Gone", value: "0")
    gone.recording_studio_trashable_trash!(actor: user)
    { text: text, section: section, content: content }
  end

  def record_stat(content, label:, value:, unit: nil)
    content.record(RecordingStudioPresskits::Stat, parent_recording: content) do |stat|
      stat.label = label
      stat.value = value
      stat.unit = unit
    end
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
