# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class FactPayloadTest < ActiveSupport::TestCase
  test "includes every fact key and keeps blank optionals as nil" do
    fact = RecordingStudioPresskits::Fact.new(
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
      RecordingStudioPresskits::Api::FactPayload.for(fact)
    )
  end

  test "omits blank optional fields as nil" do
    fact = RecordingStudioPresskits::Fact.new(label: "Completed", value: "2025", unit: "  ", description: nil)

    assert_equal(
      {
        label: "Completed",
        value: "2025",
        unit: nil,
        description: nil,
        source_url: nil,
        as_of_date: nil
      },
      RecordingStudioPresskits::Api::FactPayload.for(fact)
    )
  end

  test "section payload leaves a text section at four keys" do
    built = sections_with_facts
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

  test "section payload lists active facts in order with display settings" do
    built = sections_with_facts
    section = built.fetch(:section)
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    facts = payload.fetch(:facts)
    labels = facts.map { |entry| entry[:label] }

    assert_equal "Project facts", payload[:title]
    assert_equal "On the books", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::FactsSection", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    assert_equal({ style: "cards", columns: 3 }, payload[:display])
    assert_equal ["Floor area", "Completed"], labels
    assert_equal %i[label value unit description source_url as_of_date], facts.first.keys
    assert_equal "m²", facts.first[:unit]
    refute_includes labels, "Gone"
  end

  test "facts section api serializer returns display and facts" do
    built = sections_with_facts
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudioPresskits::FactsSection").fetch(:serializer)

    assert_equal payload.fetch(:facts), serializer.call(content.recordable, recording: content).fetch(:facts)
    assert_equal payload.fetch(:display), serializer.call(content.recordable, recording: content).fetch(:display)
  end

  test "fact requires label and value and accepts an http source" do
    fact = RecordingStudioPresskits::Fact.new(label: "", value: "", source_url: "ftp://example.com")

    refute fact.valid?
    assert_includes fact.errors[:label], "can't be blank"
    assert_includes fact.errors[:value], "can't be blank"
    assert_includes fact.errors[:source_url], "must be an HTTP or HTTPS link"

    fact.label = "Employees"
    fact.value = "85"
    fact.source_url = "https://example.com/team"
    assert fact.valid?
  end

  test "facts section validates display style and columns and keeps defaults" do
    section = RecordingStudioPresskits::FactsSection.new

    assert_equal "list", section.display_style
    assert_equal 3, section.columns
    assert section.valid?

    section.display_style = "chart"
    section.columns = 5
    refute section.valid?
    assert_includes section.errors[:display_style], "is not included in the list"
    assert_includes section.errors[:columns], "is not included in the list"

    section.display_style = "table"
    section.columns = 2
    assert section.valid?
  end

  test "formatted value joins a unit without a trailing space" do
    with_unit = RecordingStudioPresskits::Fact.new(label: "Floor area", value: "420", unit: "m²")
    without_unit = RecordingStudioPresskits::Fact.new(label: "Completed", value: "2025", unit: "  ")

    assert_equal "420 m²", with_unit.formatted_value
    assert_equal "2025", without_unit.formatted_value
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Fact payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "fact-payload-#{SecureRandom.hex(4)}@example.com",
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

  def sections_with_facts
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
      content_type: "RecordingStudioPresskits::FactsSection",
      actor: user,
      title: "Project facts",
      subtitle: "On the books"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    root.revise(content, actor: user) do |recordable|
      recordable.display_style = "cards"
      recordable.columns = 3
    end
    record_fact(content, label: "Floor area", value: "420", unit: "m²")
    record_fact(content, label: "Completed", value: "2025")
    gone = record_fact(content, label: "Gone", value: "0")
    gone.recording_studio_trashable_trash!(actor: user)
    { text: text, section: section, content: content }
  end

  def record_fact(content, label:, value:, unit: nil)
    content.record(RecordingStudioPresskits::Fact, parent_recording: content) do |fact|
      fact.label = label
      fact.value = value
      fact.unit = unit
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
