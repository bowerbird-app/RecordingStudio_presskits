# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"
require "recording_studio_api"

class PressKitPayloadTest < ActiveSupport::TestCase
  def setup
    self.class.register_api!
  end

  def self.register_api!
    return if @api_registered

    RecordingStudioPresskits::Api.register!
    @api_registered = true
  end

  test "press kit show payload passes the API serializer check" do
    _root, kit = kit_with_subtitle

    payload = serialize(kit)

    assert_equal "Spring launch", payload[:title]
    assert_equal "Collection released", payload[:subtitle]
    assert_nil payload[:description]
  end

  test "a brand revise stays saved when the API serializer check runs" do
    root, kit = kit_with_subtitle
    color_before = kit.recordable.brand_color

    updated = root.revise(kit) { |press_kit| press_kit.brand_color = "#BFDBFE" }
    payload = serialize(updated)

    assert_equal "#BFDBFE", updated.reload.recordable.brand_color
    refute_equal color_before, updated.recordable.brand_color
    assert_equal "#BFDBFE", payload[:brand_color]
    assert_equal "Collection released", payload[:subtitle]
  end

  test "other press kit recordable serializers pass the API serializer check" do
    built = kit_with_sections

    serialize(built.fetch(:kit))
    serialize(built.fetch(:text_section))
    serialize(built.fetch(:text))
    serialize(built.fetch(:quote))
    serialize(built.fetch(:stat))
    serialize(built.fetch(:item))
    serialize(built.fetch(:podcast))
    serialize(built.fetch(:credit))
    serialize(built.fetch(:credit_line))
    serialize(built.fetch(:files_section))
    serialize(built.fetch(:video_section))
    serialize(built.fetch(:stats_section))
    serialize(built.fetch(:list_section))
    serialize(built.fetch(:podcast_section))
    serialize(built.fetch(:location_section))
    serialize(built.fetch(:credits_section))
    serialize(built.fetch(:quote_section))
  end

  private

  def serialize(recording)
    RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(recording)
  end

  def kit_with_subtitle
    root, kit = kit_tree
    revised = root.revise(kit) { |press_kit| press_kit.subtitle = "Collection released" }
    [root, revised]
  end

  def kit_with_sections
    root, kit = kit_with_subtitle
    user = owner_for(root)
    text_section = add_section(kit, user, "RecordingStudioPresskits::Text", title: "Notes")
    text = RecordingStudioPresskits::KitQuery.section_content(text_section)
    quote_section = add_section(kit, user, "RecordingStudioPresskits::QuoteSection", title: "Quotes")
    quote_content = RecordingStudioPresskits::KitQuery.section_content(quote_section)
    quote = quote_content.record(
      RecordingStudioPresskits::Quote, parent_recording: quote_content, actor: user
    ) do |entry|
      entry.body = "A line"
      entry.name = "Ada"
    end
    stats_section = add_section(kit, user, "RecordingStudioPresskits::StatsSection", title: "Stats")
    stats_content = RecordingStudioPresskits::KitQuery.section_content(stats_section)
    stat = stats_content.record(
      RecordingStudioPresskits::Stat, parent_recording: stats_content, actor: user
    ) do |entry|
      entry.label = "Shows"
      entry.value = "12"
    end
    list_section = add_section(kit, user, "RecordingStudioPresskits::ListSection", title: "List")
    list_content = RecordingStudioPresskits::KitQuery.section_content(list_section)
    item = list_content.record(
      RecordingStudioPresskits::ListItem, parent_recording: list_content, actor: user
    ) do |entry|
      entry.key = "Label"
      entry.value = "Value"
    end
    podcast_section = add_section(kit, user, "RecordingStudioPresskits::PodcastSection", title: "Listen")
    podcast_content = RecordingStudioPresskits::KitQuery.section_content(podcast_section)
    podcast = podcast_content.record(
      RecordingStudioPresskits::Podcast, parent_recording: podcast_content, actor: user
    ) do |entry|
      entry.url = "https://open.spotify.com/episode/0"
      entry.title = "One"
    end
    credits_section = add_section(kit, user, "RecordingStudioPresskits::CreditsSection", title: "Credits")
    credits_content = RecordingStudioPresskits::KitQuery.section_content(credits_section)
    credit = root.record(RecordingStudioPresskits::Credit, parent_recording: root, actor: user) do |entry|
      entry.name = "Ada"
    end
    credit_line = credits_content.record(
      RecordingStudioPresskits::CreditLine, parent_recording: credits_content, actor: user
    ) do |entry|
      entry.role = "Writer"
      entry.credit_recording_id = credit.id
    end
    files_section = add_section(kit, user, "RecordingStudioPresskits::Files", title: "Documents")
    video_section = add_section(
      kit, user, "RecordingStudioPresskits::VideoSection", title: "Trailer", subtitle: "Two minutes"
    )
    location_section = add_section(kit, user, "RecordingStudioPresskits::LocationSection", title: "Places")

    {
      kit: kit,
      text_section: text_section,
      text: text,
      quote_section: quote_section,
      quote: quote,
      stats_section: stats_section,
      stat: stat,
      list_section: list_section,
      item: item,
      podcast_section: podcast_section,
      podcast: podcast,
      credits_section: credits_section,
      credit: credit,
      credit_line: credit_line,
      files_section: RecordingStudioPresskits::KitQuery.section_content(files_section),
      video_section: RecordingStudioPresskits::KitQuery.section_content(video_section),
      location_section: RecordingStudioPresskits::KitQuery.section_content(location_section)
    }
  end

  def add_section(kit, user, content_type, title:, subtitle: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: content_type,
      actor: user,
      title: title,
      subtitle: subtitle
    )
  end

  def kit_tree
    root = RecordingStudio.root_recording_for(Workspace.create!(name: "Press kit payload #{SecureRandom.hex(4)}"))
    kit = root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = "Spring launch" }
    [root, kit]
  end

  def owner_for(root_recording)
    previous = Current.actor
    user = User.create!(
      email: "press-kit-payload-#{SecureRandom.hex(4)}@example.com",
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
