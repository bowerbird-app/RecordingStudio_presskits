# frozen_string_literal: true

require "test_helper"

class KitIndexTest < Minitest::Test
  Kit = Struct.new(:title)
  Recording = Struct.new(:id, :recordable_id, :recordable, :name)

  def setup
    @spring = recording(1, 10, "Spring launch")
    @autumn = recording(2, 20, "Autumn recap")
    @later = recording(3, 30, "Winter premiere")
    @untitled = recording(4, 40, nil, name: "Untitled kit")
    @recordings = [@spring, @autumn, @later, @untitled]
  end

  def test_all_keeps_order_and_ignores_an_unknown_status
    assert_equal titles(@recordings), titles(listed(status: "nope"))
    assert_equal "all", RecordingStudioPresskits::KitIndex.status_from("later")
    assert_equal "draft", RecordingStudioPresskits::KitIndex.status_from("draft")
  end

  def test_published_is_live_now_and_draft_skips_live_and_scheduled
    assert_equal ["Spring launch"], titles(listed(status: "published", published: [10], scheduled: [30]))
    assert_equal ["Autumn recap", "Untitled kit"], titles(listed(status: "draft", published: [10], scheduled: [30]))
  end

  def test_a_kit_with_no_publishable_counts_as_draft
    @recordings = [@untitled]
    assert_equal ["Untitled kit"], titles(listed(status: "draft", published: [], scheduled: []))
    assert_empty listed(status: "published", published: [], scheduled: [])
  end

  def test_search_matches_the_title_only_and_ignores_case
    assert_equal ["Spring launch"], titles(listed(status: "all", query: "  LAUNCH "))
    assert_equal ["Untitled kit"], titles(listed(status: "all", query: "untitled"))
    assert_empty listed(status: "all", query: "harbour")
  end

  def test_search_and_status_apply_together
    assert_equal ["Autumn recap"], titles(listed(status: "draft", query: "autumn", published: [10], scheduled: [30]))
    assert_empty listed(status: "published", query: "autumn", published: [10], scheduled: [30])
  end

  def test_a_blank_query_does_not_filter
    assert_equal titles(@recordings), titles(listed(status: "all", query: "   "))
  end

  private

  def recording(id, recordable_id, title, name: nil)
    Recording.new(id, recordable_id, Kit.new(title), name)
  end

  def listed(status:, query: "", published: [], scheduled: [])
    index = RecordingStudioPresskits::KitIndex.new(@recordings, status: status, query: query)
    index.define_singleton_method(:ids_for) do |scope_name|
      scope_name == :published ? published : scheduled
    end
    index.records
  end

  def titles(recordings)
    recordings.map { |recording| recording.recordable.title.presence || recording.name }
  end
end
