# frozen_string_literal: true

require "test_helper"

class PressKitMetricsTest < ActiveSupport::TestCase
  setup do
    @previous_actor = Current.actor
    @owner = User.create!(
      email: "metrics-owner-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @staff = User.create!(
      email: "metrics-staff-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @outsider = User.create!(
      email: "metrics-denied-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @owner
    @workspace = Workspace.create!(name: "Metrics Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
    grant = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @owner)
    raise grant.error if grant.failure?

    @live = @root.record(RecordingStudioPresskits::PressKit) { |kit| kit.title = "Live kit" }
    @trashed = @root.record(RecordingStudioPresskits::PressKit) { |kit| kit.title = "Trashed kit" }
    RecordingStudioPresskits.create_section!(
      press_kit_recording: @trashed,
      content_type: "RecordingStudioPresskits::Text",
      actor: @owner,
      title: "Gone"
    )
    @trashed.recording_studio_trashable_trash!(actor: @owner)

    RecordingStudioPresskits.create_section!(
      press_kit_recording: @live,
      content_type: "RecordingStudioPresskits::Text",
      actor: @owner,
      title: "Bio"
    )
    RecordingStudioPresskits.create_section!(
      press_kit_recording: @live,
      content_type: "RecordingStudioPresskits::Images",
      actor: @owner,
      title: "Stills"
    )
    RecordingStudioPresskits.create_section!(
      press_kit_recording: @live,
      content_type: "RecordingStudioPresskits::QuoteSection",
      actor: @owner,
      title: "Praise"
    )
    original_id = @live.recordable_id
    @root.revise(@live, actor: @owner) { |kit| kit.title = "Live kit, revised" }
    @live.reload
    raise "expected a new snapshot" if @live.recordable_id == original_id

    @admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    @admin_recording = RecordingStudio.root_recording_for(@admin_root)
    ensure_admin_access!(@staff)
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "live kit metrics ignore trash and extra snapshots" do
    result = execute_metric("press_kits.total")
    expected = RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      trashed_at: nil
    ).count

    assert_equal expected, result.value
    assert_operator expected, :>=, 1
    refute_includes live_kit_ids, @trashed.id
    assert_includes live_kit_ids, @live.id
    assert_equal 1, RecordingStudio::Recording.where(id: @live.id).count
  end

  test "created_over_time counts live kits in the window" do
    result = execute_metric(
      "press_kits.created_over_time",
      interval: :day,
      start_at: 2.days.ago,
      end_at: 1.day.from_now
    )
    expected = RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      trashed_at: nil,
      created_at: 2.days.ago...1.day.from_now
    ).count

    assert_equal :timeseries, result.type
    assert_equal expected, result.data.sum { |row| row[:value].to_i }
  end

  test "by_section_type counts live sections under live kits" do
    result = execute_metric("press_kits.by_section_type")
    expected = expected_section_counts
    actual = result.data.to_h { |row| [row[:key], row[:value]] }

    assert_equal :breakdown, result.type
    expected.each do |type, count|
      assert_equal count, actual[type], type
    end
    text_type = "RecordingStudioPresskits::Text"
    assert_operator actual.fetch(text_type, 0), :>=, 1
    assert_operator actual.fetch("RecordingStudioPresskits::Images", 0), :>=, 1
    assert_operator actual.fetch("RecordingStudioPresskits::QuoteSection", 0), :>=, 1
  end

  test "staff with AdminRoot view may see metrics and a non-admin may not" do
    assert RecordingStudioPresskits::Api::Access.can_view?(grant_context(@staff))
    refute RecordingStudioPresskits::Api::Access.can_view?(grant_context(@outsider))
    refute RecordingStudioPresskits::Api::Access.can_view?(grant_context(@owner))
  end

  private

  def execute_metric(identifier, **)
    RecordingStudioMetrics.execute(
      identifier,
      context: RecordingStudioMetrics::Context.new(
        actor: @staff,
        scope: :site,
        site_authorized: true
      ),
      cache: false,
      **
    )
  end

  def live_kit_ids
    RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      trashed_at: nil
    ).pluck(:id)
  end

  def expected_section_counts
    kits = RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      trashed_at: nil
    )
    sections = RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits::KitSection.name,
      trashed_at: nil,
      parent_recording_id: kits.select(:id)
    )
    RecordingStudio::Recording.where(
      trashed_at: nil,
      parent_recording_id: sections.select(:id),
      recordable_type: RecordingStudioPresskits.section_types
    ).group(:recordable_type).distinct.count
  end

  def grant_context(actor)
    grant = Struct.new(:actor).new(actor)
    Struct.new(:access_grant).new(grant)
  end

  def ensure_admin_access!(actor)
    recording = @admin_recording
    return if RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)

    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    return if result.success?

    manager = User.find_by(email: "admin@admin.com")
    raise result.error if manager.blank? || manager == actor

    grant = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: :admin,
      manager_actor: manager
    )
    raise grant.error if grant.failure?
  end
end
