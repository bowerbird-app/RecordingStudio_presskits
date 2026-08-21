# frozen_string_literal: true

require "test_helper"

class PressKitMixinsTest < ActiveSupport::TestCase
  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "mixins-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @user
    @workspace = Workspace.create!(name: "Mixin Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording: @root,
      actor: @user
    )
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "press kit children reorder through orderable apis and log on the parent" do
    kit = record_press_kit("Spring launch")
    hero = record_fake_block(kit, "Hero")
    quotes = record_fake_block(kit, "Quotes")

    children = kit.recording_studio_orderable_children
    assert_equal [hero.id, quotes.id], children.map(&:id)
    assert_kind_of FakeBlock, children.first.recordable

    kit.recording_studio_orderable_reorder!(
      ordered_recording_ids: [quotes.id, hero.id],
      actor: @user
    )

    reordered = kit.recording_studio_orderable_children
    assert_equal [quotes.id, hero.id], reordered.map(&:id)
    assert_equal 0, quotes.reload.recording_studio_orderable_position
    assert_equal 1, hero.reload.recording_studio_orderable_position

    event = kit.events.find_by!(action: "reordered")
    assert_equal [quotes.id.to_s, hero.id.to_s], event.metadata.fetch("ordered_recording_ids")

    kit.recording_studio_orderable_move!(hero, to_index: 0, actor: @user)
    assert_equal [hero.id, quotes.id], kit.recording_studio_orderable_children.map(&:id)
  end

  test "dummy workspace can reorder press kit siblings without ordering folders" do
    first_kit = record_press_kit("Spring launch")
    second_kit = record_press_kit("Autumn recap")
    folder = RecordingStudio.record!(
      action: "created",
      recordable: Folder.new(name: "Docs #{SecureRandom.hex(4)}"),
      root_recording: @root,
      parent_recording: @root
    ).recording

    children = @root.recording_studio_orderable_children
    assert_equal [first_kit.id, second_kit.id], children.map(&:id)
    refute_includes children.map(&:id), folder.id

    @root.recording_studio_orderable_reorder!(
      ordered_recording_ids: [second_kit.id, first_kit.id],
      actor: @user
    )

    assert_equal [second_kit.id, first_kit.id], @root.recording_studio_orderable_children.map(&:id)
  end

  test "trash and restore a press kit through trashable apis" do
    kit = record_press_kit("Spring launch")
    hero = record_fake_block(kit, "Hero")

    kit.recording_studio_trashable_trash!(actor: @user)

    kit.reload
    hero.reload
    assert kit.trashed_at.present?
    assert_equal true, kit.trash_root
    assert hero.trashed_at.present?
    assert_equal 1, kit.events.where(action: "trashed").count
    refute_includes RecordingStudio::Recording.recording_studio_trashable_active, kit
    assert_includes RecordingStudio::Recording.recording_studio_trashable_trash_roots, kit

    kit.recording_studio_trashable_restore!(actor: @user)

    kit.reload
    hero.reload
    assert_nil kit.trashed_at
    assert_equal false, kit.trash_root
    assert_nil hero.trashed_at
    assert_equal 1, kit.events.where(action: "restored").count
    assert_includes RecordingStudio::Recording.recording_studio_trashable_active, kit
  end

  test "trash a fake block without a section addon" do
    kit = record_press_kit("Spring launch")
    hero = record_fake_block(kit, "Hero")

    hero.recording_studio_trashable_trash!(actor: @user)

    hero.reload
    kit.reload
    assert hero.trashed_at.present?
    assert_equal true, hero.trash_root
    assert_nil kit.trashed_at
    assert_equal 1, hero.events.where(action: "trashed").count
  end

  test "accessible denies trash when the actor lacks edit" do
    kit = record_press_kit("Spring launch")
    stranger = User.create!(
      email: "stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    error = assert_raises(ArgumentError) do
      kit.recording_studio_trashable_trash!(actor: stranger)
    end
    assert_match(/Not authorized to trash/, error.message)
    assert_nil kit.reload.trashed_at
  end

  test "accessible denies reorder when the actor lacks edit" do
    kit = record_press_kit("Spring launch")
    hero = record_fake_block(kit, "Hero")
    quotes = record_fake_block(kit, "Quotes")
    stranger = User.create!(
      email: "stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    error = assert_raises(ArgumentError) do
      kit.recording_studio_orderable_reorder!(
        ordered_recording_ids: [quotes.id, hero.id],
        actor: stranger
      )
    end
    assert_match(/Not authorized to reorder/, error.message)
  end

  test "duplicate a press kit in place including its fake block child" do
    kit = record_press_kit("Spring launch")
    record_fake_block(kit, "Hero")

    duplicate = kit.duplicate_in_place!(actor: @user)

    assert_equal @root, duplicate.parent_recording
    assert_equal @root, duplicate.root_recording
    assert_kind_of RecordingStudioPresskits::PressKit, duplicate.recordable
    assert_equal "Spring launch (Copy)", duplicate.recordable.title
    refute_equal kit.id, duplicate.id
    assert_equal 1, duplicate.events.where(action: "duplicated").count

    copied_children = duplicate.child_recordings.to_a
    assert_equal 1, copied_children.size
    assert_kind_of FakeBlock, copied_children.first.recordable
    assert_equal "Hero (Copy)", copied_children.first.recordable.title
    assert_equal duplicate, copied_children.first.parent_recording
  end

  test "duplication service copies a press kit under the same workspace" do
    kit = record_press_kit("Office hours")
    record_fake_block(kit, "Quotes")

    result = RecordingStudioDuplicatable::Services::DuplicationService.call(
      recording: kit,
      actor: @user
    )

    assert_predicate result, :success?
    duplicate = result.value
    assert_equal "Office hours (Copy)", duplicate.recordable.title
    assert_equal ["Quotes (Copy)"], duplicate.child_recordings.map { |child| child.recordable.title }
  end

  test "accessible denies duplicate when the actor lacks edit" do
    kit = record_press_kit("Spring launch")
    stranger = User.create!(
      email: "stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_raises(RecordingStudioDuplicatable::AccessDenied) do
      kit.duplicate_in_place!(actor: stranger)
    end
  end

  test "mixin engines are mounted and declarations still validate" do
    assert RecordingStudio.validate_recordable_declarations!
    routes = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

    assert(routes.any? { |path| path.start_with?("/recording_studio_orderable") })
    assert(routes.any? { |path| path.start_with?("/recording_studio_trashable") })
    assert(routes.any? { |path| path.start_with?("/recording_studio_duplicatable") })
  end

  private

  def record_press_kit(title)
    @root.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "#{title} #{SecureRandom.hex(4)}"
    end
  end

  def record_fake_block(kit_recording, title)
    kit_recording.record(FakeBlock, parent_recording: kit_recording) do |fake_block|
      fake_block.title = title
    end
  end
end
