# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class VideoPayloadTest < ActiveSupport::TestCase
  ZOO_URL = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
  RICK_URL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

  test "a saved video payload is the six public readers" do
    root, kit = kit_tree
    user = owner_for(root)
    content = video_content(kit, user)
    video = record_video(
      content,
      actor: user,
      url: ZOO_URL,
      title: "Me at the zoo",
      description: "The first video uploaded to YouTube."
    )

    assert_equal(
      {
        title: "Me at the zoo",
        url: ZOO_URL,
        description: "The first video uploaded to YouTube.",
        provider: "youtube",
        canonical_url: ZOO_URL,
        content_type: "video"
      },
      RecordingStudioPresskits::Api::VideoPayload.for(video.recordable)
    )
    payload = RecordingStudioPresskits::Api::VideoPayload.for(video.recordable)
    refute payload.key?(:summary)
    refute payload.key?(:thumbnail_url)
    refute payload.key?(:caption)
  end

  test "section payload adds videos for a video section and leaves text at four keys" do
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
      content_type: "RecordingStudioPresskits::VideoSection",
      actor: user,
      title: "Trailer",
      subtitle: "Two minutes"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    text_content = RecordingStudioPresskits::KitQuery.section_content(text)
    first = record_video(content, actor: user, url: ZOO_URL, title: "Me at the zoo", description: "First")
    second = record_video(content, actor: user, url: RICK_URL, title: "Second reel", description: "Later")
    gone = record_video(content, actor: user, url: ZOO_URL, title: "Gone", description: "Hidden")
    gone.recording_studio_trashable_trash!(actor: user)

    assert_equal(
      {
        title: "Notes",
        subtitle: nil,
        content_type: "RecordingStudioPresskits::Text",
        content_id: text_content.id
      },
      RecordingStudioPresskits::Api::SectionPayload.for(text.recordable, text)
    )

    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    assert_equal "Trailer", payload[:title]
    assert_equal "Two minutes", payload[:subtitle]
    assert_equal "RecordingStudioPresskits::VideoSection", payload[:content_type]
    assert_equal content.id, payload[:content_id]
    assert_equal [ZOO_URL, RICK_URL], payload.fetch(:videos).map { |entry| entry[:url] }
    assert_equal %i[title url description provider canonical_url content_type], payload.fetch(:videos).first.keys
    assert_equal [first.recordable.title, second.recordable.title], payload.fetch(:videos).map { |entry| entry[:title] }
    refute_includes payload.fetch(:videos).map { |entry| entry[:title] }, "Gone"

    registry = fake_api_registry
    with_recording_studio_api(registry) do
      RecordingStudioPresskits::Api.register!
    end
    serializer = registry.types.fetch("RecordingStudioPresskits::VideoSection").fetch(:serializer)
    assert_equal payload.fetch(:videos), serializer.call(content.recordable, recording: content).fetch(:videos)
  end

  private

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Video payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "video-payload-#{SecureRandom.hex(4)}@example.com",
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

  def video_content(kit, user)
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::VideoSection",
      actor: user
    )
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def record_video(content, actor:, url:, title:, description:)
    content.record(RecordingStudioVideo::Video, parent_recording: content, actor: actor) do |video|
      video.url = url
      video.title = title
      video.description = description
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
