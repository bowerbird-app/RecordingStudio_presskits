# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class LocationPayloadTest < ActiveSupport::TestCase
  test "a saved location payload keeps every public field" do
    _root, kit = kit_tree
    section = add_location(
      kit,
      title: "Project location",
      name: "The Pavilion",
      locality: "Melbourne",
      region: "Victoria",
      country_code: "AU",
      latitude: -37.81,
      longitude: 144.96
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)

    assert_equal(
      {
        name: "The Pavilion",
        address_line_1: nil,
        address_line_2: nil,
        locality: "Melbourne",
        region: "Victoria",
        postal_code: nil,
        country_code: "AU",
        latitude: -37.81,
        longitude: 144.96
      },
      RecordingStudioPresskits::Api::LocationPayload.for(content.recordable)
    )
  end

  test "section payload leaves a text section at four keys" do
    _root, kit = kit_tree
    text = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::Text",
      title: "Notes"
    )
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

  test "section payload nests the location under a location section" do
    _root, kit = kit_tree
    section = add_location(
      kit,
      title: "Project location",
      name: "The Pavilion",
      locality: "Melbourne",
      country_code: "AU",
      latitude: -37.81,
      longitude: 144.96
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)

    assert_equal "Project location", payload[:title]
    assert_nil payload[:subtitle]
    assert_equal "RecordingStudio::Location::Location", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    assert_equal "The Pavilion", payload.dig(:location, :name)
    assert_equal "Melbourne", payload.dig(:location, :locality)
    assert_equal "AU", payload.dig(:location, :country_code)
    assert_in_delta(-37.81, payload.dig(:location, :latitude))
    assert_in_delta(144.96, payload.dig(:location, :longitude))
    refute payload.key?(:videos)
  end

  test "an empty location still serializes optional fields as nil" do
    _root, kit = kit_tree
    section = add_location(kit)
    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)

    RecordingStudioPresskits::Api::LocationPayload::KEYS.each do |key|
      assert payload[:location].key?(key), key
      assert_nil payload[:location][key], key
    end
  end

  test "location section api serializer returns the nested location" do
    _root, kit = kit_tree
    section = add_location(kit, name: "The Pavilion", locality: "Melbourne")
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    registry = fake_api_registry
    with_recording_studio_api(registry) { RecordingStudioPresskits::Api.register! }
    serializer = registry.types.fetch("RecordingStudio::Location::Location").fetch(:serializer)

    assert_equal(
      RecordingStudioPresskits::Api::LocationPayload.for(content.recordable),
      serializer.call(content.recordable)
    )
  end

  test "map url prefers coordinates and hides when the place is blank" do
    _root, kit = kit_tree
    blank = RecordingStudioPresskits::KitQuery.section_content(add_location(kit)).recordable
    named = RecordingStudioPresskits::KitQuery.section_content(
      add_location(kit, name: "The Pavilion", locality: "Melbourne", country_code: "AU")
    ).recordable
    coords = RecordingStudioPresskits::KitQuery.section_content(
      add_location(kit, latitude: -37.81, longitude: 144.96)
    ).recordable

    assert_nil RecordingStudioPresskits::LocationContent.map_url(blank)
    refute RecordingStudioPresskits::LocationContent.visible?(blank)
    assert_includes RecordingStudioPresskits::LocationContent.map_url(named), "openstreetmap.org/search?query="
    assert_includes RecordingStudioPresskits::LocationContent.map_url(named), CGI.escape("Melbourne, Australia")
    assert_includes RecordingStudioPresskits::LocationContent.map_url(coords), "mlat=-37.81"
    assert_includes RecordingStudioPresskits::LocationContent.map_url(coords), "mlon=144.96"
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Location payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def add_location(kit, title: nil, **attributes)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudio::Location::Location",
      title: title
    )
    return section if attributes.empty?

    content = RecordingStudioPresskits::KitQuery.section_content(section)
    kit.root_recording.revise(content) do |location|
      attributes.each { |name, value| location.public_send(:"#{name}=", value) }
    end
    section
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
