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
      icon: " building-office-2 "
    )

    assert_equal(
      {
        label: "Floor area",
        value: "420",
        unit: "m²",
        description: "Total internal floor area",
        icon: "building-office-2"
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
        icon: nil
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

  test "section payload lists active stats in order" do
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
    refute payload.key?(:columns)
    refute payload.key?(:display)
    refute payload.key?(:facts)
    assert_equal ["Floor area", "Completed"], labels
    assert_equal %i[label value unit description icon], stats.first.keys
    refute stats.first.key?(:source_url)
    refute stats.first.key?(:as_of_date)
    assert_equal "m²", stats.first[:unit]
    refute_includes labels, "Gone"
  end

  test "stats section api serializer returns stats" do
    built = sections_with_stats
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudioPresskits::StatsSection").fetch(:serializer)
    serialized = serializer.call(content.recordable, recording: content)

    assert_equal payload.fetch(:stats), serialized.fetch(:stats)
    refute serialized.key?(:columns)
    refute serialized.key?(:display)
  end

  test "stat requires label and value" do
    stat = RecordingStudioPresskits::Stat.new(label: "", value: "")

    refute stat.respond_to?(:source_url)
    refute stat.respond_to?(:as_of_date)
    refute stat.valid?
    assert_includes stat.errors[:label], "can't be blank"
    assert_includes stat.errors[:value], "can't be blank"

    stat.label = "Team members"
    stat.value = "85"
    stat.unit = nil
    stat.description = "Studio staff"
    stat.icon = " users "
    assert stat.valid?
    assert_equal "users", stat.icon

    stat.icon = "not-an-icon"
    refute stat.valid?
    assert_includes stat.errors[:icon], "is not included in the list"

    stat.icon = ""
    assert stat.valid?
    assert_nil stat.icon
  end

  test "stats section has no columns attribute" do
    section = RecordingStudioPresskits::StatsSection.new

    refute section.respond_to?(:columns)
    refute section.respond_to?(:display_style)
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
    refute content.recordable.respond_to?(:columns)
  end

  test "drop columns migration removes the columns column" do
    connection = ActiveRecord::Base.connection
    connection.add_column :recording_studio_stats_sections, :columns, :integer, default: 3, null: false
    RecordingStudioPresskits::StatsSection.reset_column_information
    assert connection.column_exists?(:recording_studio_stats_sections, :columns)

    load Rails.root.join("db/migrate/20261014130000_drop_columns_from_recording_studio_stats_sections.rb")
    DropColumnsFromRecordingStudioStatsSections.drop_columns
    RecordingStudioPresskits::StatsSection.reset_column_information

    refute connection.column_exists?(:recording_studio_stats_sections, :columns)
    refute RecordingStudioPresskits::StatsSection.new.respond_to?(:columns)
  ensure
    if connection&.column_exists?(:recording_studio_stats_sections, :columns)
      connection.remove_column :recording_studio_stats_sections, :columns
    end
    RecordingStudioPresskits::StatsSection.reset_column_information
  end

  test "drop source and as of migration removes those columns" do
    connection = ActiveRecord::Base.connection
    connection.add_column :recording_studio_stats, :source_url, :string
    connection.add_column :recording_studio_stats, :as_of_date, :date
    RecordingStudioPresskits::Stat.reset_column_information
    assert connection.column_exists?(:recording_studio_stats, :source_url)
    assert connection.column_exists?(:recording_studio_stats, :as_of_date)

    load Rails.root.join("db/migrate/20261014140000_drop_source_and_as_of_from_recording_studio_stats.rb")
    DropSourceAndAsOfFromRecordingStudioStats.drop_source_and_as_of
    RecordingStudioPresskits::Stat.reset_column_information

    refute connection.column_exists?(:recording_studio_stats, :source_url)
    refute connection.column_exists?(:recording_studio_stats, :as_of_date)
    refute RecordingStudioPresskits::Stat.new.respond_to?(:source_url)
    refute RecordingStudioPresskits::Stat.new.respond_to?(:as_of_date)
  ensure
    if connection&.column_exists?(:recording_studio_stats, :source_url)
      connection.remove_column :recording_studio_stats, :source_url
    end
    if connection&.column_exists?(:recording_studio_stats, :as_of_date)
      connection.remove_column :recording_studio_stats, :as_of_date
    end
    RecordingStudioPresskits::Stat.reset_column_information
  end

  test "add icon migration adds the icon column" do
    connection = ActiveRecord::Base.connection
    connection.remove_column :recording_studio_stats, :icon
    RecordingStudioPresskits::Stat.reset_column_information
    refute connection.column_exists?(:recording_studio_stats, :icon)

    load Rails.root.join("db/migrate/20261014150000_add_icon_to_recording_studio_stats.rb")
    AddIconToRecordingStudioStats.add_icon
    RecordingStudioPresskits::Stat.reset_column_information

    assert connection.column_exists?(:recording_studio_stats, :icon)
    assert RecordingStudioPresskits::Stat.new.respond_to?(:icon)
  ensure
    unless connection&.column_exists?(:recording_studio_stats, :icon)
      connection&.add_column(:recording_studio_stats, :icon, :string)
    end
    RecordingStudioPresskits::Stat.reset_column_information
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
