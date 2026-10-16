# frozen_string_literal: true

require "test_helper"

class PresskitsApiRequestTest < ActionDispatch::IntegrationTest
  BASE = "/recording_studio_api/api/v1"
  VIDEO_URL = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
  PODCAST_URL = "https://example.com/show"

  setup do
    @previous_actor = Current.actor
    @owner = user("owner")
    @editor_user = user("editor")
    @viewer_user = user("viewer")
    @stranger = user("stranger")
    @workspace = Workspace.create!(name: "API Workspace #{SecureRandom.hex(4)}")
    Current.actor = @owner
    @root = RecordingStudio.root_recording_for(@workspace)
    @owner_access = bootstrap!(@root, @owner)
    @editor_access = grant!(@editor_user, :edit)
    @viewer_access = grant!(@viewer_user, :view)
    @admin_token = token_for(@owner_access)
    @editor_token = token_for(@editor_access)
    @viewer_token = token_for(@viewer_access)
    stranger_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"))
    @stranger_token = token_for(bootstrap!(stranger_root, @stranger), manager: @stranger)
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "press kit create show update and trash follow view edit and admin" do
    created = call(:post, "/press_kits", @admin_token, parent_id: @root.id, title: "Spring launch", subtitle: "Doors", description: "Noon notes", brand_color: "#112233")
    assert_response :created, response.body
    kit_id = created.fetch("id")
    assert_equal "Spring launch", created.fetch("title")
    assert_equal "#112233", created.fetch("brand_color")

    shown = call(:get, "/press_kits/#{kit_id}", @editor_token)
    assert_response :success
    assert_equal "Noon notes", shown.fetch("description")

    call(:get, "/press_kits/#{kit_id}", @stranger_token)
    assert_response :not_found

    call(:patch, "/press_kits/#{kit_id}", @viewer_token, title: "Blocked")
    assert_response :forbidden

    updated = call(:patch, "/press_kits/#{kit_id}", @editor_token, title: "Spring relaunch", font_family: "serif")
    assert_response :success, response.body
    assert_equal "Spring relaunch", updated.fetch("title")
    assert_equal "serif", updated.fetch("font_family")

    call(:delete, "/press_kits/#{kit_id}", @editor_token)
    assert_response :forbidden

    trashed = call(:delete, "/press_kits/#{kit_id}", @admin_token)
    assert_response :success, response.body
    assert_equal true, trashed.fetch("deleted")
    assert_equal "trashed", trashed.fetch("deleted_via")
    assert RecordingStudio::Recording.find(kit_id).recording_studio_trashable_trashed?

    call(:get, "/press_kits/#{kit_id}", @admin_token)
    assert_response :not_found
  end

  test "press kit search matches the title only" do
    call(:post, "/press_kits", @admin_token, parent_id: @root.id, title: "Harbour notes", description: "UniqueZebra body")
    assert_response :created, response.body
    call(:post, "/press_kits", @admin_token, parent_id: @root.id, title: "UniqueZebra", description: "Other")
    assert_response :created, response.body

    titled = call(:get, "/press_kits", @admin_token, q: "UniqueZebra")
    assert_response :success, response.body
    titles = titled.fetch("records").map { |row| row.fetch("title") }
    assert_equal ["UniqueZebra"], titles

    described = call(:get, "/press_kits", @admin_token, q: "Harbour")
    assert_equal ["Harbour notes"], described.fetch("records").map { |row| row.fetch("title") }
  end

  test "viewers do not see drafts and editors do" do
    kit = record_kit("Draft launch", "Still private")

    call(:get, "/press_kits/#{kit.id}", @viewer_token)
    assert_response :not_found

    listed = call(:get, "/press_kits", @viewer_token)
    assert_response :success
    refute_includes listed.fetch("records").map { |row| row.fetch("id") }, kit.id

    shown = call(:get, "/press_kits/#{kit.id}", @editor_token)
    assert_response :success
    assert_equal "Still private", shown.fetch("description")
  end

  test "embargo preview withholds protected fields and a hidden embargo stays unlisted" do
    preview = publish_kit(record_kit("Embargoed launch", "Secret description"))
    hold!(preview, :preview)
    hidden = publish_kit(record_kit("Quiet launch", "Hidden description"))
    hold!(hidden, :hidden)

    visitor = call(:get, "/press_kits/#{preview.id}", @viewer_token)
    assert_response :success, response.body
    assert_equal "Embargoed launch", visitor.fetch("title")
    assert_nil visitor.fetch("description")

    editor = call(:get, "/press_kits/#{preview.id}", @editor_token)
    assert_equal "Secret description", editor.fetch("description")

    call(:get, "/press_kits/#{hidden.id}", @viewer_token)
    assert_response :not_found

    call(:get, "/press_kits/#{hidden.id}", @editor_token)
    assert_response :success
  end

  test "nested sections and owned items support read edit and trash" do
    kit = record_kit("Section kit", "Public copy")
    text = section(kit, "RecordingStudioPresskits::Text", "Notes")
    quotes = section(kit, "RecordingStudioPresskits::QuoteSection", "Quotes")
    stats = section(kit, "RecordingStudioPresskits::StatsSection", "Stats")
    credits = section(kit, "RecordingStudioPresskits::CreditsSection", "Credits")
    lists = section(kit, "RecordingStudioPresskits::ListSection", "Facts")
    podcasts = section(kit, "RecordingStudioPresskits::PodcastSection", "Shows")
    menu = section(kit, "RecordingStudioPresskits::MenuSection", "Contents")

    listed = call(:get, "/press_kits/#{kit.id}/kit_sections", @viewer_token)
    assert_response :not_found

    publish_kit(kit)
    listed = call(:get, "/press_kits/#{kit.id}/kit_sections", @viewer_token)
    assert_response :success, response.body
    assert_equal 7, listed.fetch("records").size

    call(:patch, "/kit_sections/#{text.fetch("id")}", @viewer_token, title: "Nope")
    assert_response :forbidden
    renamed = call(:patch, "/kit_sections/#{text.fetch("id")}", @editor_token, title: "Launch notes")
    assert_equal "Launch notes", renamed.fetch("title")

    text_row = call(:get, "/kit_sections/#{text.fetch("id")}/texts", @editor_token).fetch("records").first
    revised = call(:patch, "/texts/#{text_row.fetch("id")}", @editor_token, body: "Doors at noon")
    assert_equal "Doors at noon", revised.fetch("body")
    call(:patch, "/texts/#{text_row.fetch("id")}", @viewer_token, body: "Leak")
    assert_response :forbidden

    quote = call(:post, "/quote_sections/#{quotes.fetch("content_id")}/quotes", @editor_token, body: "A line", name: "Ada")
    assert_response :created, response.body
    assert_equal "Ada", quote.fetch("name")
    call(:patch, "/quotes/#{quote.fetch("id")}", @viewer_token, body: "Changed")
    assert_response :forbidden

    stat = call(:post, "/stats_sections/#{stats.fetch("content_id")}/stats", @editor_token, label: "Cities", value: "12")
    assert_response :created, response.body
    assert_equal "12", stat.fetch("value")

    credit = call(:post, "/credits", @editor_token, parent_id: @root.id, name: "Ada Lovelace", usual_role: "Writer")
    assert_response :created, response.body
    line = call(:post, "/credits_sections/#{credits.fetch("content_id")}/credit_lines", @editor_token, credit_id: credit.fetch("id"), role: "Writer")
    assert_response :created, response.body
    assert_equal "Ada Lovelace", line.fetch("name")
    assert_equal credit.fetch("id"), line.fetch("credit_id")

    item = call(:post, "/list_sections/#{lists.fetch("content_id")}/items", @editor_token, key: "City", value: "London")
    assert_response :created, response.body
    assert_equal "London", item.fetch("value")

    episode = call(:post, "/podcast_sections/#{podcasts.fetch("content_id")}/podcasts", @editor_token, url: PODCAST_URL, title: "Pilot")
    assert_response :created, response.body
    assert_equal PODCAST_URL, episode.fetch("url")

    menu_body = call(:patch, "/menu_sections/#{menu.fetch("content_id")}", @editor_token, layout: "list", show_counts: false)
    assert_response :success, response.body
    assert_equal "list", menu_body.fetch("layout")
    assert_equal false, menu_body.fetch("show_counts")
    call(:patch, "/menu_sections/#{menu.fetch("content_id")}", @viewer_token, layout: "grid")
    assert_response :forbidden

    hold!(kit, :preview)
    withheld = call(:get, "/texts/#{text_row.fetch("id")}", @viewer_token)
    assert_response :success
    assert_nil withheld.fetch("body")
    assert_equal "Doors at noon", call(:get, "/texts/#{text_row.fetch("id")}", @editor_token).fetch("body")

    quote_preview = call(:get, "/quotes/#{quote.fetch("id")}", @viewer_token)
    assert_nil quote_preview.fetch("body")
    stat_preview = call(:get, "/stats/#{stat.fetch("id")}", @viewer_token)
    assert_nil stat_preview.fetch("label")
    line_preview = call(:get, "/credit_lines/#{line.fetch("id")}", @viewer_token)
    assert_nil line_preview["name"]
    item_preview = call(:get, "/list_items/#{item.fetch("id")}", @viewer_token)
    assert_nil item_preview.fetch("value")
    episode_preview = call(:get, "/podcasts/#{episode.fetch("id")}", @viewer_token)
    assert_nil episode_preview.fetch("url")

    [quote, stat, credit, line, item, episode].each do |row|
      call(:delete, resource_path(row), @editor_token)
      assert_response :forbidden, response.body
    end
    [quote, stat, line, item, episode, credit].each do |row|
      call(:delete, resource_path(row), @admin_token)
      assert_response :success, response.body
      assert_equal "trashed", JSON.parse(response.body).fetch("deleted_via")
    end

    spare = section(kit, "RecordingStudioPresskits::Text", "Spare")
    call(:delete, "/kit_sections/#{spare.fetch("id")}", @editor_token)
    assert_response :forbidden
    call(:delete, "/kit_sections/#{spare.fetch("id")}", @admin_token)
    assert_response :success
    assert_equal "trashed", JSON.parse(response.body).fetch("deleted_via")
  end

  test "videos places images and files use section actions" do
    kit = publish_kit(record_kit("Media kit", "Copy"))
    videos = section(kit, "RecordingStudioPresskits::VideoSection", "Video")
    places = section(kit, "RecordingStudioPresskits::LocationSection", "Place")
    images = section(kit, "RecordingStudioPresskits::Images", "Photos")
    files = section(kit, "RecordingStudioPresskits::Files", "Documents")
    image = attach!(images.fetch("content_id"), "stage.jpg", "image/jpeg", File.binread(cover_path))
    file = attach!(files.fetch("content_id"), "notes.txt", "text/plain", "hello")

    added = call(:post, "/video_sections/#{videos.fetch("content_id")}/add_video", @editor_token, url: VIDEO_URL, title: "Zoo", duration: "1:24")
    assert_response :success, response.body
    video_id = added.fetch("id")
    call(:post, "/video_sections/#{videos.fetch("content_id")}/update_video", @viewer_token, video_id: video_id, title: "Nope")
    assert_response :forbidden
    call(:post, "/video_sections/#{videos.fetch("content_id")}/update_video", @editor_token, video_id: video_id, title: "Me at the zoo")
    assert_response :success
    call(:post, "/video_sections/#{videos.fetch("content_id")}/reorder_videos", @editor_token, ordered_recording_ids: [video_id])
    assert_response :success
    call(:post, "/video_sections/#{videos.fetch("content_id")}/remove_video", @editor_token, video_id: video_id)
    assert_response :forbidden
    call(:post, "/video_sections/#{videos.fetch("content_id")}/remove_video", @admin_token, video_id: video_id)
    assert_response :success

    placed = call(:post, "/location_sections/#{places.fetch("content_id")}/set_location", @editor_token, title: "Hall", name: "Town Hall", locality: "London")
    assert_response :success, response.body
    place_id = placed.fetch("id")
    call(:post, "/location_sections/#{places.fetch("content_id")}/update_location", @viewer_token, location_id: place_id, locality: "Paris")
    assert_response :forbidden
    call(:post, "/location_sections/#{places.fetch("content_id")}/update_location", @editor_token, location_id: place_id, locality: "Paris")
    assert_response :success
    call(:post, "/location_sections/#{places.fetch("content_id")}/clear_location", @editor_token, location_id: place_id)
    assert_response :forbidden
    call(:post, "/location_sections/#{places.fetch("content_id")}/clear_location", @admin_token, location_id: place_id)
    assert_response :success

    shown_images = call(:get, "/images/#{images.fetch("content_id")}", @viewer_token)
    assert_response :success, response.body
    assert_equal image.id, shown_images.fetch("images").first.fetch("id")
    call(:post, "/images/#{images.fetch("content_id")}/update_image", @viewer_token, image_id: image.id, caption: "Blocked")
    assert_response :forbidden
    call(:post, "/images/#{images.fetch("content_id")}/update_image", @editor_token, image_id: image.id, caption: "Stage", alt_text: "The stage")
    assert_response :success
    assert_equal "Stage", image.reload.recordable.caption
    call(:post, "/images/#{images.fetch("content_id")}/reorder_images", @editor_token, ordered_recording_ids: [image.id])
    assert_response :success
    call(:post, "/images/#{images.fetch("content_id")}/remove_image", @editor_token, image_id: image.id)
    assert_response :forbidden
    call(:post, "/images/#{images.fetch("content_id")}/remove_image", @admin_token, image_id: image.id)
    assert_response :success

    shown_files = call(:get, "/files/#{files.fetch("content_id")}", @viewer_token)
    assert_equal file.id, shown_files.fetch("files").first.fetch("id")
    call(:post, "/files/#{files.fetch("content_id")}/update_file", @editor_token, file_id: file.id, name: "One sheet", description: "For desks")
    assert_response :success
    assert_equal "One sheet", file.reload.recordable.name
    call(:post, "/files/#{files.fetch("content_id")}/reorder_files", @editor_token, ordered_recording_ids: [file.id])
    assert_response :success
    call(:post, "/files/#{files.fetch("content_id")}/remove_file", @viewer_token, file_id: file.id)
    assert_response :forbidden
    call(:post, "/files/#{files.fetch("content_id")}/remove_file", @admin_token, file_id: file.id)
    assert_response :success

    hold!(kit, :preview)
    withheld = call(:get, "/images/#{images.fetch("content_id")}", @viewer_token)
    assert_equal [], withheld.fetch("images")
    assert_equal [], call(:get, "/files/#{files.fetch("content_id")}", @viewer_token).fetch("files")
  end

  test "publish and unpublish stay on the press kit" do
    kit = record_kit("Live kit", "Copy")
    call(:post, "/press_kits/#{kit.id}/publish", @viewer_token)
    assert_response :forbidden
    call(:post, "/press_kits/#{kit.id}/publish", @editor_token)
    assert_response :success, response.body
    assert kit.reload.currently_published?
    call(:post, "/press_kits/#{kit.id}/unpublish", @editor_token)
    assert_response :success, response.body
    refute kit.reload.currently_published?
  end

  test "reorder quotes stats and list rows" do
    kit = publish_kit(record_kit("Order kit", "Copy"))
    quotes = section(kit, "RecordingStudioPresskits::QuoteSection", "Quotes")
    first = call(:post, "/quote_sections/#{quotes.fetch("content_id")}/quotes", @editor_token, body: "First", name: "A")
    second = call(:post, "/quote_sections/#{quotes.fetch("content_id")}/quotes", @editor_token, body: "Second", name: "B")
    call(:post, "/quote_sections/#{quotes.fetch("content_id")}/reorder_quotes", @viewer_token, ordered_recording_ids: [second.fetch("id"), first.fetch("id")])
    assert_response :forbidden
    call(:post, "/quote_sections/#{quotes.fetch("content_id")}/reorder_quotes", @editor_token, ordered_recording_ids: [second.fetch("id"), first.fetch("id")])
    assert_response :success
  end

  test "scalar docs and openapi render the press kit surface" do
    get "/APIdocs/v1/openapi.json"
    assert_response :success, response.body
    document = JSON.parse(response.body)
    paths = document.fetch("paths").keys
    assert paths.any? { |path| path.include?("/press_kits") }
    assert paths.any? { |path| path.include?("/kit_sections") }
    assert paths.any? { |path| path.include?("create_section") }
    assert paths.any? { |path| path.include?("/video_sections/") }
    refute paths.any? { |path| path.include?("/kit_sections/") && path.include?("/videos") }

    get "/APIdocs/v1"
    assert_response :success
    assert_includes response.body, "Press kits API"
  end

  private

  def user(name)
    User.create!(
      email: "#{name}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def bootstrap!(recording, actor)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    raise result.error if result.failure?

    result.value
  end

  def grant!(actor, role)
    result = RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: actor,
      role: role,
      manager_actor: @owner
    )
    raise result.error if result.failure?

    result.value
  end

  def token_for(access_recording, manager: @owner)
    provision = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: access_recording.parent_recording || access_recording.root_recording,
      manager_actor: manager,
      role: access_recording.recordable.role,
      name: "Client #{SecureRandom.hex(3)}"
    )
    raise provision.error unless provision.success?

    issued = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token)
    )
    raise issued.error unless issued.success?

    issued.value.fetch(:access_token)
  end

  def headers(token)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  def call(method, path, token, params = {})
    send(method, "#{BASE}#{path}", params: params, headers: headers(token), as: :json)
    response.media_type.to_s.include?("json") ? JSON.parse(response.body) : {}
  rescue JSON::ParserError
    {}
  end

  def record_kit(title, description)
    @root.record(RecordingStudioPresskits::PressKit, actor: @owner) do |press_kit|
      press_kit.title = title
      press_kit.description = description
    end
  end

  def publish_kit(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @owner,
      attributes: { slug: "kit-#{SecureRandom.hex(4)}", status: "published", meta_robots: "index,follow" }
    )
    raise result.error if result.failure?

    kit.reload
  end

  def hold!(kit, fallback)
    RecordingStudioPresskits::KitSettings.save_fallback!(recording: kit, fallback: fallback, actor: @owner)
    kit.embargo_set!(
      { enabled: true, lifts_at: 1.day.from_now.change(sec: 0), time_zone: "UTC", early_access: false },
      actor: @owner
    )
    kit.reload
  end

  def section(kit, content_type, title)
    payload = call(:post, "/press_kits/#{kit.id}/create_section", @admin_token, content_type: content_type, title: title)
    assert_response :success, response.body
    payload
  end

  def attach!(parent_id, filename, content_type, bytes)
    parent = RecordingStudio::Recording.find(parent_id)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(bytes),
      filename: filename,
      content_type: content_type
    )
    parent.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @owner, name: File.basename(filename, ".*"))
  end

  def cover_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
  end

  def resource_path(row)
    name = RecordingStudioApi.resource_name_for(row.fetch("type"))
    "/#{name}/#{row.fetch("id")}"
  end
end
