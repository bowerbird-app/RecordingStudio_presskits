# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "base64"
require "json"

class PodcastSectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  SPOTIFY = "https://open.spotify.com/episode/4iV5W9uYEdYUVa79Axb7Rh"
  APPLE = "https://podcasts.apple.com/us/podcast/example/id123?i=100"
  SITE = "https://example.com/show"
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")

  setup do
    @previous_actor = Current.actor
    @previous_http = RecordingStudioPresskits::PodcastArtwork.http
    RecordingStudioPresskits::PodcastArtwork.http = offline_http
    @user = User.create!(
      email: "podcast-section-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Podcast Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
    RecordingStudioPresskits::PodcastArtwork.http = @previous_http
  end

  test "create section stores the heading and no episode row" do
    kit = record_kit("Spring launch")

    assert_difference -> { RecordingStudioPresskits::KitSection.count }, 1 do
      assert_difference -> { RecordingStudioPresskits::PodcastSection.count }, 1 do
        assert_no_difference -> { RecordingStudioPresskits::Podcast.count } do
          @section = RecordingStudioPresskits.create_section!(
            press_kit_recording: kit,
            content_type: "RecordingStudioPresskits::PodcastSection",
            actor: @user,
            title: "Listen",
            subtitle: "This week"
          )
        end
      end
    end

    content = section_content(@section)
    assert_equal "Listen", @section.recordable.title
    assert_equal "This week", @section.recordable.subtitle
    assert_kind_of RecordingStudioPresskits::PodcastSection, content.recordable
    assert_equal(
      {
        title: "Listen",
        subtitle: "This week",
        content_type: "RecordingStudioPresskits::PodcastSection",
        content_id: content.id,
        podcasts: []
      },
      RecordingStudioPresskits::Api::SectionPayload.for(@section.recordable, @section)
    )
  end

  test "episodes hang off the podcast section and a revise keeps the old snapshot" do
    kit = record_kit("Spring launch")
    content = section_content(add_podcast_section(kit))
    first = record_podcast(content, url: SPOTIFY, title: "Pilot")
    snapshot_id = first.recordable_id

    assert_equal [first.id], RecordingStudioPresskits::PodcastSection.active_podcasts(content).map(&:id)
    refute RecordingStudio.capability_enabled?(:orderable, for: "RecordingStudioPresskits::PodcastSection")

    assert_difference -> { RecordingStudioPresskits::Podcast.count }, 1 do
      @root.revise(first, actor: @user) { |episode| episode.title = "Renamed" }
    end

    assert_equal "Pilot", RecordingStudioPresskits::Podcast.find(snapshot_id).title
    assert_equal "Renamed", first.reload.recordable.title
    refute_equal snapshot_id, first.recordable_id
  end

  test "a link that is not http fails validation" do
    content = section_content(add_podcast_section(record_kit("Spring launch")))

    error = assert_raises(ActiveRecord::RecordInvalid) do
      record_podcast(content, url: "spotify:episode:abc", title: "Nope")
    end

    assert_includes error.record.errors[:url], "needs to start with http:// or https://"
  end

  test "deleting one episode trashes that recording and deleting the section trashes the rest" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)
    section = add_podcast_section(kit, title: "Listen")
    content = section_content(section)
    first = record_podcast(content, url: SPOTIFY, title: "Pilot")
    second = record_podcast(content, url: SITE, title: "Notes")

    delete recording_studio_presskits.press_kit_section_podcast_path(kit, section, first)

    assert_redirected_to recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert first.reload.trashed_at.present?
    assert_nil second.reload.trashed_at
    assert_equal [second.id], RecordingStudioPresskits::PodcastSection.active_podcasts(content).map(&:id)

    delete recording_studio_presskits.press_kit_section_path(kit, section)

    assert second.reload.trashed_at.present?
    assert content.reload.trashed_at.present?
    assert section.reload.trashed_at.present?
    assert_nil kit.reload.trashed_at
  end

  test "the editor adds edits and lists episodes" do
    kit = record_kit("Spring launch")
    sign_in @user
    switch_to_root(@root)

    post recording_studio_presskits.press_kit_sections_path(kit),
         params: { type: "RecordingStudioPresskits::PodcastSection" }
    follow_redirect!
    assert_response :success
    section = podcast_section(kit)
    assert_equal "Podcasts", section.recordable.title
    assert_includes response.body, "Add an episode"
    assert_includes response.body, "A show they can press play on."

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    new_episode = recording_studio_presskits.new_press_kit_section_podcast_path(kit, section)
    assert_select "#presskits-section-actions a[href='#{new_episode}']" do
      assert_select "span", text: "Podcast"
    end

    post recording_studio_presskits.press_kit_section_podcasts_path(kit, section), params: {
      podcast: { url: SPOTIFY, title: "Pilot", show_name: "Launch notes", aired_on: "2026-03-02", duration: "34 min" }
    }
    episode = RecordingStudioPresskits::PodcastSection.active_podcasts(section_content(section)).first
    assert_redirected_to recording_studio_presskits.edit_press_kit_section_podcast_path(kit, section, episode)
    follow_redirect!
    assert_includes response.body, "Podcast added."
    assert_select "input[name='podcast[url]'][value='#{SPOTIFY}']"
    assert_select "input[name='podcast[title]'][value='Pilot']"

    patch recording_studio_presskits.press_kit_section_podcast_path(kit, section, episode), params: {
      podcast: { url: SPOTIFY, title: "Pilot cut", show_name: "Launch notes", duration: "34 min" }
    }
    follow_redirect!
    assert_equal "Pilot cut", episode.reload.recordable.title

    get recording_studio_presskits.edit_press_kit_section_path(kit, section)
    assert_includes response.body, "Pilot cut"
    assert_select "[aria-label='Remove podcast']"
  end

  test "the public row shows a stored cover a player and a fallback tile" do
    kit = record_kit("Spring launch")
    @root.revise(kit, actor: @user) { |press_kit| press_kit.brand_color = "#1D4ED8" }
    section = add_podcast_section(kit, title: "Listen", subtitle: "This week")
    content = section_content(section)
    RecordingStudioPresskits::PodcastArtwork.http = spotify_http
    stored = record_podcast(content, url: SPOTIFY, show_name: "Launch notes", duration: "34 min")
    RecordingStudioPresskits::PodcastArtwork.store!(stored, actor: @user)
    record_podcast(content, url: SITE, title: "Studio notes")
    record_podcast(content, url: APPLE, title: "Apple cut")

    text = RecordingStudioPresskits::KitDownload::TextFile.call(kit)
    assert_includes text, "Fetched title"
    assert_includes text, "Launch notes"
    assert_includes text, SPOTIFY
    assert_includes text, "Studio notes"
    assert_includes text, SITE

    payload = RecordingStudioPresskits::Api::SectionPayload.for(section.recordable, section)
    spotify = payload[:podcasts].find { |row| row[:url] == SPOTIFY }
    assert_equal "Fetched title", spotify[:title]
    assert_equal "Launch notes", spotify[:show_name]
    assert_equal "Spotify", spotify[:service]
    assert_equal "https://open.spotify.com/embed/episode/4iV5W9uYEdYUVa79Axb7Rh", spotify[:embed_url]
    assert stored.reload.recordable.fetched_artwork.attached?
    assert_equal SPOTIFY, stored.recordable.artwork_source_url

    publish_kit!(kit)
    get "/published/#{kit.publishable_child_recording.id}/spring-launch-podcasts"
    assert_response :success
    assert_includes response.body, "Listen"
    assert_includes response.body, "w-[83.333%]"
    assert_includes response.body, "md:w-[calc((100%-2rem)/3)]"
    assert_includes response.body, "snap-x"
    assert_select "img[data-podcast-cover]"
    assert_select "[data-podcast-fallback]"
    assert_includes response.body, RecordingStudioPresskits::KitBranding.for(kit.reload).brand_color
    assert_select "iframe[data-podcast-embed][src='https://open.spotify.com/embed/episode/4iV5W9uYEdYUVa79Axb7Rh']"
    assert_select "iframe[data-podcast-embed][src='https://embed.podcasts.apple.com/us/episode/100']"
    assert_includes response.body, "Listen on Spotify"
    assert_includes response.body, "Listen on Apple Podcasts"
    assert_includes response.body, "Copy link"
    assert_includes response.body, "34 min"
    assert_select "a[href='#{SITE}'][target='_blank']"
    assert_select "[data-recording-studio-presskits--podcast-carousel-target='previous'][hidden]"
    assert_select "[data-recording-studio-presskits--podcast-carousel-target='next'][hidden]"
    cards = css_select("[data-podcast-card]").to_html
    refute_includes cards, "i.scdn.co"
    refute_includes cards, "recordable"
    refute_includes cards, "actor"
  end

  test "fetched artwork fills a blank title and leaves a typed title alone" do
    content = section_content(add_podcast_section(record_kit("Spring launch")))
    RecordingStudioPresskits::PodcastArtwork.http = spotify_http
    blank = record_podcast(content, url: SPOTIFY)
    typed = record_podcast(content, url: SPOTIFY, title: "Kept title")

    RecordingStudioPresskits::PodcastArtwork.store!(blank, actor: @user)
    RecordingStudioPresskits::PodcastArtwork.store!(typed, actor: @user)

    assert_equal "Fetched title", blank.reload.recordable.title
    assert_equal "Fetched show", blank.recordable.show_name
    assert blank.recordable.fetched_artwork.attached?
    assert_equal "Kept title", typed.reload.recordable.title
    assert_equal "Fetched show", typed.recordable.show_name

    calls = 0
    RecordingStudioPresskits::PodcastArtwork.http = lambda { |_uri|
      calls += 1
      [404, "", "text/html", nil]
    }
    RecordingStudioPresskits::PodcastArtwork.store!(blank, actor: @user)
    assert_equal 0, calls
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def add_podcast_section(kit, title: nil, subtitle: nil)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "RecordingStudioPresskits::PodcastSection",
      actor: @user,
      title: title,
      subtitle: subtitle
    )
  end

  def podcast_section(kit)
    RecordingStudioPresskits::KitQuery.sections_for(kit).find do |section|
      RecordingStudioPresskits::KitQuery.section_content(section).recordable.is_a?(RecordingStudioPresskits::PodcastSection)
    end
  end

  def section_content(section)
    RecordingStudioPresskits::KitQuery.section_content(section)
  end

  def record_podcast(content, url:, title: nil, show_name: nil, duration: nil)
    content.record(RecordingStudioPresskits::Podcast, parent_recording: content, actor: @user) do |podcast|
      podcast.url = url
      podcast.title = title
      podcast.show_name = show_name
      podcast.duration = duration
    end
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-podcasts", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    result.value
  end

  def switch_to_root(root)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root.id,
        return_to: "/recording_studio_presskits"
      }
    }
    follow_redirect! if response.redirect?
  end

  def offline_http
    lambda { |_uri| [404, "", "text/html", nil] }
  end

  def spotify_http
    lambda do |uri|
      if uri.path == "/oembed"
        body = { thumbnail_url: "https://i.scdn.co/image/abc.png", title: "Fetched title", author_name: "Fetched show" }.to_json
        [200, body, "application/json", nil]
      else
        [200, PNG, "image/png", nil]
      end
    end
  end
end
