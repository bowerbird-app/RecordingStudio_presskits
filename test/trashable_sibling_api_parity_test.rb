# frozen_string_literal: true

require "test_helper"

class TrashableSiblingApiParityTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  MAPPED_SOURCES = [
    "app/models/recording_studio_presskits/facts_section.rb",
    "app/components/recording_studio_presskits/quote_section/component.rb",
    "app/components/recording_studio_presskits/quote_section/edit_component.rb",
    "lib/recording_studio_presskits/credits.rb",
    "lib/recording_studio_presskits/quote_order.rb",
    "lib/recording_studio_presskits/metrics.rb",
    "app/controllers/recording_studio_presskits/quotes_controller.rb",
    "app/controllers/recording_studio_presskits/facts_controller.rb",
    "app/controllers/recording_studio_presskits/quote_images_controller.rb",
    "app/models/recording_studio_presskits/list_section.rb",
    "app/controllers/recording_studio_presskits/list_items_controller.rb"
  ].freeze

  def test_pins_trashable_0_9_by_tag_and_gemspec
    gemspec = File.read(File.join(ROOT, "recording_studio_presskits.gemspec"))
    gemfile = File.read(File.join(ROOT, "Gemfile"))
    dummy = File.read(File.join(ROOT, "test/dummy/Gemfile"))

    assert_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.9"'
    assert_match(
      /recording_studio_trashable", "~> 0\.9".*tag: "v0\.9\.0"/,
      gemfile
    )
    assert_match(
      /recording_studio_trashable".*tag: "v0\.9\.0"/,
      dummy
    )
    refute_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.8"'
    refute_match(/recording_studio_trashable[^\n]*tag: "v0\.8\.0"/, gemfile)
    refute_match(/recording_studio_trashable[^\n]*tag: "v0\.8\.0"/, dummy)
  end

  def test_mapped_call_sites_use_trashable_sibling_api_not_raw_trashed_at
    MAPPED_SOURCES.each do |relative|
      source = File.read(File.join(ROOT, relative))

      refute_includes source, "trashed_at: nil", relative
      refute_includes source, "trashed_at.present?", relative
      refute_includes source, "trashed_at.nil?", relative
      refute_includes source, "trashed_at.blank?", relative
      refute_includes source, "merge(RecordingStudio::Recording.recording_studio_trashable_active)", relative
    end

    facts = File.read(File.join(ROOT, "app/models/recording_studio_presskits/facts_section.rb"))
    quotes = File.read(File.join(ROOT, "app/components/recording_studio_presskits/quote_section/component.rb"))
    quote_edit = File.read(File.join(ROOT, "app/components/recording_studio_presskits/quote_section/edit_component.rb"))
    credits = File.read(File.join(ROOT, "lib/recording_studio_presskits/credits.rb"))
    quote_order = File.read(File.join(ROOT, "lib/recording_studio_presskits/quote_order.rb"))
    metrics = File.read(File.join(ROOT, "lib/recording_studio_presskits/metrics.rb"))
    quotes_controller = File.read(File.join(ROOT, "app/controllers/recording_studio_presskits/quotes_controller.rb"))
    facts_controller = File.read(File.join(ROOT, "app/controllers/recording_studio_presskits/facts_controller.rb"))
    quote_images = File.read(File.join(ROOT, "app/controllers/recording_studio_presskits/quote_images_controller.rb"))

    list_section = File.read(File.join(ROOT, "app/models/recording_studio_presskits/list_section.rb"))
    list_items = File.read(File.join(ROOT, "app/controllers/recording_studio_presskits/list_items_controller.rb"))

    assert_includes list_section, "recording_studio_trashable_trashed?"
    assert_includes list_items, "recording_studio_trashable_kept_sql"
    assert_includes facts, "recording_studio_trashable_trashed?"
    assert_includes quotes, "recording_studio_trashable_trashed?"
    assert_includes quote_edit, "recording_studio_trashable_trashed?"
    assert_includes credits, "recording_studio_trashable_kept?"
    assert_includes credits, "recording_studio_trashable_trashed?"
    assert_includes credits, "recording_studio_trashable_kept_sql"
    assert_includes credits, "recording_studio_trashable_active.where(recordable_type: Credit.name)"
    assert_includes quote_order, "recording_studio_trashable_kept_sql"
    assert_includes metrics, "recording_studio_trashable_kept_sql"
    assert_includes quotes_controller, "recording_studio_trashable_kept_sql"
    assert_includes facts_controller, "recording_studio_trashable_kept_sql"
    assert_includes quote_images, "recording_studio_trashable_kept_sql"

    kit_query = File.read(File.join(ROOT, "lib/recording_studio_presskits/kit_query.rb"))
    assert_includes kit_query, "def live_kits"
    assert_includes kit_query, "RecordingStudio::Recording.recording_studio_trashable_active"
    assert_includes kit_query, "merge(\n          RecordingStudio::Recording.recording_studio_trashable_active"
    assert_includes kit_query, ".merge(RecordingStudio::Recording.recording_studio_trashable_active)"
    refute_includes kit_query, "recording_studio_trashable_kept_sql"
  end

  def test_legacy_section_tree_keeps_update_bang_trash_root_copy_not_void
    source = File.read(File.join(ROOT, "lib/recording_studio_presskits/legacy_section_tree.rb"))

    assert_includes source, "content_recording.trashed_at.blank?"
    assert_includes source, "section_recording.update!(trashed_at: content_recording.trashed_at, trash_root: was_root)"
    refute_includes source, "void_recording!"
    refute_includes source, "recording_studio_trashable_void!"
  end

  def test_changelog_and_migration_notes_document_trashable_0_9
    changelog = File.read(File.join(ROOT, "CHANGELOG.md"))
    notes = File.read(File.join(ROOT, "MIGRATION_NOTES.md"))
    readme = File.read(File.join(ROOT, "README.md"))

    assert_includes changelog, "## [0.54.0]"
    assert_includes changelog, "recording_studio_trashable"
    assert_includes changelog, "v0.9.0"
    assert_includes changelog, "LegacySectionTree"
    assert_includes changelog, "recording_studio_trashable_kept_sql"
    assert_includes changelog, "recording_studio_trashable_active"
    assert_includes changelog, "live_credits"
    assert_includes changelog, "KitQuery.live_kits"
    refute_includes changelog, "like main"
    assert_includes notes, "## 0.54.0"
    assert_includes notes, "~> 0.9"
    assert_includes notes, "void_recording!"
    assert_includes notes, "Where main used `where(trashed_at: nil)`"
    assert_includes notes, "Where main already used `recording_studio_trashable_active`"
    refute_includes notes, "like main"
    assert_includes readme, 'tag: "v0.9.0"'
    assert_includes readme, 'gem "recording_studio_trashable", "~> 0.9"'
  end
end
