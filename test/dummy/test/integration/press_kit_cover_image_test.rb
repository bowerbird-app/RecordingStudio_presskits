# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressKitCoverImageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "cover-image-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @workspace = Workspace.create!(name: "Cover Image Workspace #{SecureRandom.hex(4)}")
    Current.actor = @user
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "hero and grid hide a cover image when the kit has no placement" do
    kit = record_kit("Spring launch")
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-cover-image", count: 0
    assert_select "#presskits-cover-hero [data-cover-eyebrow]", text: "Press kit"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-image-card]", count: 0
    assert_select "[data-cover-ratio='9 / 16']", minimum: 1
  end

  test "public kit and editor show a library placement above the colour header" do
    kit = record_kit("Spring launch")
    photo = place_cover!(kit)
    publish_kit!(kit)

    get kit.publishable_public_path
    assert_response :success
    assert_select "#presskits-cover-image[data-cover-image] img[alt='A white gallery hall']"
    hero = css_select("[data-cover-stack]").first.to_html
    assert_operator hero.index("presskits-cover-image"), :<, hero.index("presskits-cover-hero")
    assert_includes css_select("#presskits-cover-image").first["class"], "aspect-[1440/640]"
    assert_select "#presskits-cover-hero [data-cover-eyebrow]", text: "Press kit"
    assert_select "#presskits-cover-hero h1", text: "Spring launch"

    sign_in @user
    switch_to_root(@root)
    get recording_studio_presskits.edit_press_kit_path(kit)
    assert_response :success
    assert_select "#presskits-kit-header #presskits-cover-image img[alt='A white gallery hall']"
    assert_includes response.body, "Cover image"
    assert_includes response.body, recording_studio_attachable.recording_placements_path(kit)

    get recording_studio_presskits.press_kits_path
    assert_response :success
    assert_select "[data-cover-image-card] [data-cover-image] img[alt='A white gallery hall']"
    card = css_select("[data-cover-image-card]").first.to_html
    assert_operator card.index("data-cover-image"), :<, card.index("Spring launch")
    refute_includes card, "aspect-[9/16]"
    assert_equal photo.id, kit.library_placements.first.attachment_recording.id
  end

  test "header editor opens Attachable placements and stays off the 9/16 preview" do
    kit = record_kit("Spring launch")
    place_cover!(kit)
    sign_in @user
    switch_to_root(@root)

    get recording_studio_presskits.edit_press_kit_header_path(kit)
    assert_response :success
    assert_select "a[href='#{cover_image_header_path(kit)}']", text: "Choose from the library"
    assert_select "#presskits-header-edit-preview [data-cover-image]", count: 0
    assert_select "#presskits-header-edit-preview [data-cover-ratio='9 / 16']"

    get recording_studio_attachable.recording_placements_path(kit, redirect_mode: "return_to", return_to: recording_studio_presskits.edit_press_kit_header_path(kit))
    assert_response :success
    assert_includes response.body, "recording-studio-attachable--attachment-image-picker"
    assert_includes response.body, "recording-studio-attachable--library-placement"
  end

  test "reordering sections leaves the cover placement on the kit" do
    kit = record_kit("Spring launch")
    first = record_block(kit, "Hero")
    second = record_block(kit, "Notes")
    place_cover!(kit)
    sign_in @user
    switch_to_root(@root)

    patch recording_studio_presskits.press_kit_order_path(kit), params: {
      ordered_recording_ids: [second.id, first.id]
    }
    follow_redirect!

    assert_response :success
    assert_equal [second.id, first.id], RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id)
    refute_includes RecordingStudioPresskits::KitQuery.sections_for(kit).map(&:id),
                    kit.library_placements.first.placement_recording.id
    assert_equal 1, kit.library_placements.size
  end

  private

  def record_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) { |press_kit| press_kit.title = title }
  end

  def record_block(kit, title)
    RecordingStudioPresskits.create_section!(
      press_kit_recording: kit,
      content_type: "FakeBlock",
      actor: @user,
      title: title
    )
  end

  def place_cover!(kit)
    library = @root.image_library(actor: @user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(cover_fixture_path),
      filename: "harbour-gallery.jpg",
      content_type: "image/jpeg"
    )
    photo = library.record_attachment_upload(signed_blob_id: blob.signed_id, actor: @user)
    photo.revise_attachment_metadata(actor: @user, alt_text: "A white gallery hall")
    kit.place_library_image(attachment_recording: photo, actor: @user)
    photo
  end

  def cover_fixture_path
    RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")
  end

  def cover_image_header_path(kit)
    recording_studio_attachable.recording_placements_path(
      kit,
      redirect_mode: "return_to",
      return_to: recording_studio_presskits.edit_press_kit_header_path(kit)
    )
  end

  def publish_kit!(kit)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit,
      actor: @user,
      attributes: { slug: "spring-launch-cover-image-#{SecureRandom.hex(4)}", status: "published" }
    )
    raise result.error if result.failure?

    kit.reload
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
end
