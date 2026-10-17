# frozen_string_literal: true

require "test_helper"

class TrashableSiblingApiParityIntegrationTest < ActiveSupport::TestCase
  setup do
    @previous_actor = Current.actor
    @user = User.create!(
      email: "trashable-parity-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @user
    @workspace = Workspace.create!(name: "Trashable parity #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
    grant = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise grant.error if grant.failure?

    @kit = @root.record(RecordingStudioPresskits::PressKit) { |kit| kit.title = "Parity kit" }
  end

  teardown do
    Current.actor = @previous_actor
  end

  test "Recording exposes trashable sibling helpers used by presskits" do
    assert_includes RecordingStudio::Recording.included_modules, RecordingStudioTrashable::RecordingScopes
    assert_respond_to RecordingStudio::Recording, :recording_studio_trashable_active
    assert_respond_to RecordingStudio::Recording, :recording_studio_trashable_kept_sql
    assert_respond_to @kit, :recording_studio_trashable_kept?
    assert_respond_to @kit, :recording_studio_trashable_trashed?
    assert_respond_to RecordingStudioTrashable, :void_recording!
  end

  test "kept and trashed predicates match trashed_at column semantics" do
    assert @kit.trashed_at.nil?
    assert @kit.recording_studio_trashable_kept?
    refute @kit.recording_studio_trashable_trashed?

    @kit.recording_studio_trashable_trash!(actor: @user)
    @kit.reload

    assert @kit.trashed_at.present?
    assert @kit.recording_studio_trashable_trashed?
    refute @kit.recording_studio_trashable_kept?
    assert_equal true, @kit.trash_root
  end

  test "kept_sql filters match where trashed_at nil for press kit filters" do
    gone = @root.record(RecordingStudioPresskits::PressKit) { |kit| kit.title = "Gone" }
    gone.recording_studio_trashable_trash!(actor: @user)

    legacy_ids = RecordingStudio::Recording.where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      trashed_at: nil,
      root_recording_id: @root.id
    ).order(:id).pluck(:id)
    sibling_ids = RecordingStudio::Recording.where(
      RecordingStudio::Recording.recording_studio_trashable_kept_sql
    ).where(
      recordable_type: RecordingStudioPresskits.press_kit_type_name,
      root_recording_id: @root.id
    ).order(:id).pluck(:id)

    assert_equal legacy_ids, sibling_ids
    assert_includes sibling_ids, @kit.id
    refute_includes sibling_ids, gone.id
    assert_equal sibling_ids, RecordingStudioPresskits::Metrics.live_kits(
      RecordingStudio::Recording.where(root_recording_id: @root.id)
    ).order(:id).pluck(:id)
  end

  test "child and metrics filters match main under a host default_scope" do
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::QuoteSection",
      actor: @user,
      title: "Quotes"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    quote = content.record(RecordingStudioPresskits::Quote, parent_recording: content, actor: @user) do |recordable|
      recordable.body = "Kept"
      recordable.name = "Voice"
    end
    decoy = @root.record(RecordingStudioPresskits::PressKit) { |kit| kit.title = "Decoy" }

    recording_class = RecordingStudio::Recording
    previous_default_scopes = recording_class.default_scopes.dup
    recording_class.class_eval do
      default_scope -> { where(id: decoy.id) }
    end

    begin
      legacy_child = content.child_recordings.where(
        trashed_at: nil,
        recordable_type: "RecordingStudioPresskits::Quote"
      ).find_by(id: quote.id)
      kept_sql_child = content.child_recordings.where(
        recording_class.recording_studio_trashable_kept_sql
      ).where(recordable_type: "RecordingStudioPresskits::Quote").find_by(id: quote.id)
      wrongly_unscoped = recording_class.unscoped.recording_studio_trashable_active.where(
        parent_recording_id: content.id,
        recordable_type: "RecordingStudioPresskits::Quote"
      ).find_by(id: quote.id)

      assert_nil legacy_child, "main child lookup respects host default_scope"
      assert_nil kept_sql_child, "kept_sql must use the same child_recordings base as main"
      assert_equal quote, wrongly_unscoped,
                   "adding unscoped would diverge from main under a host default_scope"

      legacy_metrics = recording_class.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name,
        trashed_at: nil,
        root_recording_id: @root.id
      ).order(:id).pluck(:id)
      metrics_ids = RecordingStudioPresskits::Metrics.live_kits(
        recording_class.where(root_recording_id: @root.id)
      ).order(:id).pluck(:id)
      active_metrics = recording_class.where(root_recording_id: @root.id)
                                      .recording_studio_trashable_active
                                      .where(recordable_type: RecordingStudioPresskits.press_kit_type_name)
                                      .order(:id).pluck(:id)

      assert_equal [decoy.id], legacy_metrics
      assert_equal legacy_metrics, metrics_ids
      assert_equal legacy_metrics, active_metrics
    ensure
      recording_class.default_scopes.replace(previous_default_scopes)
    end
  end

  test "kept_sql ANDs with a trashed_at default_scope like main where nil" do
    recording_class = RecordingStudio::Recording
    previous_default_scopes = recording_class.default_scopes.dup
    recording_class.class_eval do
      default_scope { where(trashed_at: nil) }
    end

    begin
      base = recording_class.where(root_recording_id: @root.id)
      main_sql = base.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name,
        trashed_at: nil
      ).to_sql
      kept_sql = base.where(recording_class.recording_studio_trashable_kept_sql).where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name
      ).to_sql
      active_sql = base.recording_studio_trashable_active.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name
      ).to_sql

      main_ids = base.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name,
        trashed_at: nil
      ).order(:id).pluck(:id)
      kept_ids = RecordingStudioPresskits::Metrics.live_kits(base).order(:id).pluck(:id)
      active_ids = base.recording_studio_trashable_active.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name
      ).order(:id).pluck(:id)

      assert_equal main_ids, kept_ids
      assert_equal main_ids, active_ids
      assert_includes main_sql, '"trashed_at" IS NULL'
      assert_includes kept_sql, '"trashed_at" IS NULL'
      assert_operator main_sql.scan("trashed_at").size, :>=, 2
      assert_operator kept_sql.scan("trashed_at").size, :>=, 2
      assert_equal 1, active_sql.scan("trashed_at").size,
                   "recording_studio_trashable_active unscopes first under a trashed_at default_scope"
    ensure
      recording_class.default_scopes.replace(previous_default_scopes)
    end
  end

  test "where.not trashed_at default_scope matches main at kept_sql and active call sites" do
    quote_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::QuoteSection",
      actor: @user,
      title: "Quotes"
    )
    quote_content = RecordingStudioPresskits::KitQuery.section_content(quote_section)
    quote = quote_content.record(
      RecordingStudioPresskits::Quote,
      parent_recording: quote_content,
      actor: @user
    ) do |recordable|
      recordable.body = "Kept quote"
      recordable.name = "Voice"
    end
    blob = issued_attachment_blob!(
      quote, @user,
      io: File.open(RecordingStudioPresskits::Engine.root.join("test/fixtures/files/cover.jpg")),
      filename: "quote.jpg",
      content_type: "image/jpeg"
    )
    attachment = quote.record_attachment_upload(
      signed_blob_id: attachment_signed_id(blob),
      actor: @user,
      name: "quote"
    )

    credit = RecordingStudioPresskits::Credits.create!(
      root_recording: @root,
      name: "Parity credit",
      actor: @user
    )
    credits_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::CreditsSection",
      actor: @user,
      title: "Credits"
    )
    credits_content = RecordingStudioPresskits::KitQuery.section_content(credits_section)
    line = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: credits_content,
      credit_recording: credit,
      actor: @user
    )

    assert_equal line, RecordingStudioPresskits::Credits.find_line(credits_content, line.id)
    assert_includes RecordingStudioPresskits::Metrics.live_kits(
      RecordingStudio::Recording.where(root_recording_id: @root.id)
    ).pluck(:id), @kit.id
    assert_includes RecordingStudioPresskits::Credits.active_for_root(@root)
                                                    .unscope(:includes)
                                                    .pluck(:id), credit.id
    assert_includes RecordingStudioPresskits::KitQuery.live_kits
                                                     .where(root_recording_id: @root.id)
                                                     .unscope(:includes)
                                                     .pluck(:id), @kit.id
    assert_equal quote_section, RecordingStudioPresskits::KitQuery.section_for(@kit, quote_section.id)
    assert_equal quote_content, RecordingStudioPresskits::KitQuery.section_content(quote_section)

    controller = RecordingStudioPresskits::QuoteImagesController.new
    controller.instance_variable_set(:@quote_recording, quote)
    assert_equal attachment, controller.send(:find_attachment)

    recording_class = RecordingStudio::Recording
    previous_default_scopes = recording_class.default_scopes.dup
    recording_class.class_eval do
      default_scope { where.not(trashed_at: nil) }
    end

    begin
      main_kept_kits = recording_class.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name,
        trashed_at: nil,
        root_recording_id: @root.id
      ).pluck(:id)
      assert_empty main_kept_kits,
                   "main where(trashed_at: nil) ANDs with where.not(trashed_at: nil)"

      assert_nil RecordingStudioPresskits::Credits.find_line(credits_content, line.id),
                 "find_line kept_sql must AND like main under where.not(trashed_at: nil)"
      assert_empty RecordingStudioPresskits::Metrics.live_kits(
        recording_class.where(root_recording_id: @root.id)
      ).pluck(:id),
                   "Metrics.live_kits kept_sql must AND like main"
      assert_nil controller.send(:find_attachment),
                 "QuoteImagesController#find_attachment kept_sql must AND like main"

      live_credit_ids = RecordingStudioPresskits::Credits.active_for_root(@root)
                                                        .unscope(:includes)
                                                        .pluck(:id)
      query_kit_ids = RecordingStudioPresskits::KitQuery.live_kits
                                                       .where(root_recording_id: @root.id)
                                                       .unscope(:includes)
                                                       .pluck(:id)
      active_kit_ids = recording_class.recording_studio_trashable_active.where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name,
        root_recording_id: @root.id
      ).pluck(:id)
      active_credit_ids = recording_class.recording_studio_trashable_active.where(
        recordable_type: RecordingStudioPresskits::Credit.name,
        root_recording_id: @root.id,
        parent_recording_id: @root.id
      ).pluck(:id)

      assert_includes live_credit_ids, credit.id,
                      "live_credits/_active unscopes like main under where.not(trashed_at: nil)"
      assert_equal active_credit_ids.sort, live_credit_ids.sort
      assert_includes query_kit_ids, @kit.id,
                      "KitQuery.live_kits/_active unscopes like main"
      assert_equal active_kit_ids.sort, query_kit_ids.sort
      assert_equal quote_section,
                   RecordingStudioPresskits::KitQuery.section_for(@kit, quote_section.id),
                   "ordered_active_children merge(active) unscopes like main"
      assert_equal quote_content,
                   RecordingStudioPresskits::KitQuery.section_content(quote_section),
                   "active_children merge(active) unscopes like main"
      assert_equal credits_content,
                   RecordingStudioPresskits::KitQuery.section_content(credits_section)
    ensure
      recording_class.default_scopes.replace(previous_default_scopes)
    end
  end

  test "stats and credits hide trashed children through trashable predicates" do
    stats_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::StatsSection",
      actor: @user,
      title: "Stats"
    )
    stats = RecordingStudioPresskits::KitQuery.section_content(stats_section)
    kept = stats.record(RecordingStudioPresskits::Stat, parent_recording: stats, actor: @user) do |stat|
      stat.label = "Kept"
      stat.value = "1"
    end
    trashed = stats.record(RecordingStudioPresskits::Stat, parent_recording: stats, actor: @user) do |stat|
      stat.label = "Gone"
      stat.value = "0"
    end
    trashed.recording_studio_trashable_trash!(actor: @user)

    refute RecordingStudioPresskits::StatsSection.hidden_stat?(kept)
    assert RecordingStudioPresskits::StatsSection.hidden_stat?(trashed.reload)
    assert_equal [kept.id], RecordingStudioPresskits::StatsSection.active_stats(stats).map(&:id)

    credit = RecordingStudioPresskits::Credits.create!(
      root_recording: @root,
      name: "Tom",
      actor: @user
    )
    credits_section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::CreditsSection",
      actor: @user,
      title: "Credits"
    )
    content = RecordingStudioPresskits::KitQuery.section_content(credits_section)
    line = RecordingStudioPresskits::Credits.add!(
      credits_section_recording: content,
      credit_recording: credit,
      actor: @user
    )

    assert RecordingStudioPresskits::Credits.shown_credit?(credit)
    RecordingStudioPresskits::Credits.trash!(credit, actor: @user)
    refute RecordingStudioPresskits::Credits.shown_credit?(credit.reload)
    assert_equal [line.id], RecordingStudioPresskits::Credits.lines_for(content).map(&:id)
    assert_empty RecordingStudioPresskits::Credits.visible_lines(content)
  end

  test "user trash keeps trash_root unlike void_recording" do
    section = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Bio"
    )
    section.recording_studio_trashable_trash!(actor: @user)
    section.reload

    assert section.recording_studio_trashable_trashed?
    assert_equal true, section.trash_root

    other = RecordingStudioPresskits.create_section!(
      press_kit_recording: @kit,
      content_type: "RecordingStudioPresskits::Text",
      actor: @user,
      title: "Voided"
    )
    time = Time.utc(2026, 10, 13, 12, 0, 0)
    RecordingStudioTrashable.void_recording!(other, time: time)
    other.reload

    assert other.recording_studio_trashable_trashed?
    assert_equal false, other.trash_root
    assert_in_delta time.to_f, other.trashed_at.to_f, 1
  end

  test "kept_sql fragments quote the table alias presskits would need for joins" do
    assert_equal '"recording_studio_recordings"."trashed_at" IS NULL',
                 RecordingStudio::Recording.recording_studio_trashable_kept_sql
    assert_equal '"child"."trashed_at" IS NULL',
                 RecordingStudio::Recording.recording_studio_trashable_kept_sql("child")
    assert_equal '"recording_studio_recordings"."trashed_at" IS NOT NULL',
                 RecordingStudio::Recording.recording_studio_trashable_trashed_sql
  end
end
