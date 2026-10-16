# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"
require "recording_studio_api"

class ApiRegistrationTest < ActiveSupport::TestCase
  def setup
    self.class.register_api!
  end

  def self.register_api!
    return if @api_registered

    RecordingStudioPresskits::Api.register!
    @api_registered = true
  end

  test "empty output_keys with a serializer are rejected by RecordingStudioApi" do
    error = assert_raises(RecordingStudioApi::ConfigurationError) do
      RecordingStudioApi::RecordableRegistration.new(
        recordable_type: "RecordingStudioPresskits::ListSection",
        operations: %i[index show],
        serializer: ->(*) { {} },
        output_keys: []
      )
    end
    assert_match(/Output keys are required when serializer is configured/, error.message)
  end

  test "presskits registration passes RecordingStudioApi validation without a host patch" do
    list = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::ListSection")
    quote = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::QuoteSection")
    credits = RecordingStudioApi.recordable_registration_for("RecordingStudioPresskits::CreditsSection")

    assert_equal %w[items], list.output_keys
    assert_respond_to list.serializer, :call
    assert_equal %i[index show], list.operations

    assert_empty quote.output_keys
    assert_nil quote.serializer
    assert_equal %i[index show], quote.operations

    assert_empty credits.output_keys
    assert_nil credits.serializer
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
