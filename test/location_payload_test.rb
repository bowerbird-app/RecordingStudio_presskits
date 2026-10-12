# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class LocationPayloadTest < ActiveSupport::TestCase
  test "a saved location payload is Location's api_payload" do
    root, kit = kit_tree
    user = owner_for(root)
    content = location_content(kit, user)
    location = record_location(
      content,
      actor: user,
      title: "The Pavilion",
      locality: "Melbourne",
      country_code: "AU"
    )

    payload = RecordingStudioPresskits::Api::LocationPayload.for(location.recordable)
    gem_payload = location.recordable.api_payload

    assert_equal gem_payload, payload
    assert_equal "The Pavilion", payload[:title]
    assert_equal "venue", payload[:location_type]
    assert_equal "Melbourne", payload[:locality]
    assert_equal "AU", payload[:country_code]
    assert_equal location.recordable.display_name, payload[:display_name]
    assert payload.key?(:resolved_icon)
    assert payload.key?(:full_address)
    assert payload.key?(:coordinates)
  end

  test "section payload leaves a text section at four keys" do
    built = sections_with_locations
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

  test "section payload lists active locations in created order" do
    built = sections_with_locations
    section = built.fetch(:section)
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    locations = payload.fetch(:locations)
    titles = locations.map { |entry| entry[:title] }

    assert_equal "Where to find us", payload[:title]
    assert_equal "Two rooms", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::LocationSection", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    assert_equal ["The Pavilion", "Harbour Hall"], titles
    refute_includes titles, "Gone"
    assert locations.first.key?(:display_name)
  end

  test "location section api serializer returns the section locations" do
    built = sections_with_locations
    content = built.fetch(:content)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(built.fetch(:section).recordable, built.fetch(:section))
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudioPresskits::LocationSection").fetch(:serializer)

    assert_equal payload.fetch(:locations), serializer.call(content.recordable, recording: content).fetch(:locations)
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Location payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "location-payload-#{SecureRandom.hex(4)}@example.com",
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

  def sections_with_locations
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
      content_type: "RecordingStudioPresskits::LocationSection",
      actor: user,
      title: "Where to find us",
      subtitle: "Two rooms"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    record_location(content, actor: user, title: "The Pavilion", locality: "Melbourne")
    record_location(content, actor: user, title: "Harbour Hall", locality: "Sydney")
    gone = record_location(content, actor: user, title: "Gone", locality: "Perth")
    gone.recording_studio_trashable_trash!(actor: user)
    { text: text, section: section, content: content }
  end

  def location_content(kit, user)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::LocationSection",
      actor: user
    )
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def record_location(content, actor:, title:, locality:, country_code: "AU")
    content.record(RecordingStudio::Location::Location, parent_recording: content, actor: actor) do |location|
      location.title = title
      location.location_type = "venue"
      location.locality = locality
      location.country_code = country_code
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
