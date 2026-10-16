# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"
require "recording_studio_api"

class ApiRegistrationTest < ActiveSupport::TestCase
  PRESSKITS_TYPES = %w[
    RecordingStudioPresskits::PressKit
    RecordingStudioPresskits::KitSection
    RecordingStudioPresskits::Text
    RecordingStudioPresskits::Quote
    RecordingStudioPresskits::QuoteSection
    RecordingStudioPresskits::Stat
    RecordingStudioPresskits::StatsSection
    RecordingStudioPresskits::Credit
    RecordingStudioPresskits::CreditLine
    RecordingStudioPresskits::CreditsSection
    RecordingStudioPresskits::VideoSection
    RecordingStudioPresskits::Podcast
    RecordingStudioPresskits::PodcastSection
    RecordingStudioPresskits::LocationSection
    RecordingStudioPresskits::ListItem
    RecordingStudioPresskits::ListSection
    RecordingStudioPresskits::Files
  ].freeze

  def setup
    refute defined?(PresskitsEmptyApiOutput),
           "host PresskitsEmptyApiOutput patch must not be loaded for this test"
    ancestors = RecordingStudioApi::RecordableRegistration.ancestors.map(&:name)
    refute_includes ancestors, "PresskitsEmptyApiOutput"

    self.class.boot_presskits_api!
  end

  def self.boot_presskits_api!
    return if @api_booted

    RecordingStudioApi.prepare_recordable_registries_for_reload!
    RecordingStudioPresskits::Api.register!
    RecordingStudioApi.configuration.fetch_api(:public).recordable_registry.validate!
    @api_booted = true
  end

  test "empty output_keys with a serializer are rejected by RecordingStudioApi" do
    error = assert_raises(RecordingStudioApi::ConfigurationError) do
      RecordingStudioApi::RecordableRegistration.new(
        recordable_type: "RecordingStudioPresskits::QuoteSection",
        operations: %i[index show],
        serializer: ->(*) { {} },
        output_keys: []
      )
    end
    assert_match(/Output keys are required when serializer is configured/, error.message)
  end

  test "operations-only registration without output_keys passes RecordingStudioApi validation" do
    registration = RecordingStudioApi::RecordableRegistration.new(
      recordable_type: "RecordingStudioPresskits::QuoteSection",
      operations: %i[index show]
    )

    assert_nil registration.serializer
    assert_empty registration.output_keys
    assert registration.validate!
  end

  test "whole presskits API registration boots against RecordingStudioApi with no host patch" do
    registry = RecordingStudioApi.configuration.fetch_api(:public).recordable_registry

    assert_nothing_raised { registry.validate! }

    PRESSKITS_TYPES.each do |type_name|
      registration = RecordingStudioApi.recordable_registration_for(type_name)
      assert registration, "#{type_name} was not registered"
      assert_nothing_raised { registration.validate! }
      if registration.serializer
        refute_empty registration.output_keys, "#{type_name} has a serializer but no output_keys"
      end
    end

    list = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::ListSection")
    quote = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::QuoteSection")
    credits = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::CreditsSection")

    assert_equal %w[items], list.output_keys
    assert_respond_to list.serializer, :call
    assert_equal %i[index show], list.operations

    assert_nil quote.serializer
    assert_empty quote.output_keys
    assert_equal %i[index show], quote.operations
    refute_includes operations_only_source, "output_keys"
    refute_includes operations_only_source, "serializer"
    refute_includes operations_only_source, "[]"

    assert_nil credits.serializer
    assert_empty credits.output_keys
    assert_equal %i[index show], credits.operations
    assert_includes credits.capability_actions, "add_credit"
    assert_includes credits.capability_actions, "reorder_credits"
  end

  test "list section show payload declares items and passes the API serializer check" do
    root, kit = kit_tree
    user = owner_for(root)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::ListSection",
      actor: user,
      title: "At a glance"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    content.record(
      RecordingStudioPresskits::ListItem, parent_recording: content, actor: user
    ) do |entry|
      entry.key = "Capacity"
      entry.value = "120"
      entry.icon = "star"
    end

    payload = RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(content)

    assert_equal content.id, payload[:id]
    assert_equal [{ icon: "star", key: "Capacity", value: "120" }], payload[:items]
  end

  private

  def operations_only_source
    api = File.read(File.expand_path("../lib/recording_studio_presskits/api.rb", __dir__))
    start = api.index("def operations_only_section_options")
    finish = api.index("\n      end\n", start)
    api[start..finish]
  end

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "API registration #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "api-registration-#{SecureRandom.hex(4)}@example.com",
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
end
