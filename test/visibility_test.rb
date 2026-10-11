# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/visibility"

class VisibilityTest < Minitest::Test
  FakeKit = Struct.new(:id, :recordable_type, :recordable_id, :currently_published) do
    def currently_published?
      currently_published
    end
  end

  FakeResponse = Struct.new(:headers, :status) do
    def initialize
      super({}, 200)
    end

    def set_header(key, value)
      headers[key] = value
    end
  end

  def test_blank_kit_is_unavailable
    assert_equal :unavailable, RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: nil)
  end

  def test_unpublished_visitor_is_unavailable
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", false)

    result = RecordingStudioPresskits::Visibility.stub(:editor?, false) do
      RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit, purpose: :public)
    end

    assert_equal :unavailable, result
  end

  def test_unpublished_editor_keeps_full_preview
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", false)

    result = RecordingStudioPresskits::Visibility.stub(:editor?, true) do
      RecordingStudioPresskits::Visibility.presentation_for(actor: :owner, kit: kit, purpose: :editor)
    end

    assert_equal :full, result
  end

  def test_published_authorized_actor_sees_full
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", true)

    result = RecordingStudioPresskits::Visibility.stub(:authorized_full?, true) do
      RecordingStudioPresskits::KitSettings.stub(:fallback_for, :hidden) do
        RecordingStudioPresskits::Visibility.presentation_for(actor: :visitor, kit: kit)
      end
    end

    assert_equal :full, result
  end

  def test_published_stranger_uses_fallback
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", true)

    result = RecordingStudioPresskits::Visibility.stub(:authorized_full?, false) do
      RecordingStudioPresskits::KitSettings.stub(:fallback_for, :hidden) do
        RecordingStudioPresskits::Visibility.presentation_for(actor: nil, kit: kit)
      end
    end

    assert_equal :hidden, result
  end

  def test_discoverable_is_full_or_preview_only
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", true)

    RecordingStudioPresskits::Visibility.stub(:presentation_for, :preview) do
      assert RecordingStudioPresskits::Visibility.discoverable?(actor: nil, kit: kit)
    end
    RecordingStudioPresskits::Visibility.stub(:presentation_for, :hidden) do
      refute RecordingStudioPresskits::Visibility.discoverable?(actor: nil, kit: kit)
    end
  end

  def test_apply_public_response_sets_private_cache_and_404s_hidden
    response = FakeResponse.new

    assert_equal :hidden, RecordingStudioPresskits::Visibility.apply_public_response!(
      presentation: :hidden,
      response: response
    )
    assert_equal 404, response.status
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  def test_apply_public_response_keeps_full_without_private_cache
    response = FakeResponse.new

    assert_equal :full, RecordingStudioPresskits::Visibility.apply_public_response!(
      presentation: :full,
      response: response
    )
    assert_equal 200, response.status
    assert_nil response.headers["Cache-Control"]
  end

  def test_unavailable_presentation_404s_without_kit_html_hook
    response = FakeResponse.new

    assert_equal :unavailable, RecordingStudioPresskits::Visibility.apply_public_response!(
      presentation: nil,
      response: response
    )
    assert_equal 404, response.status
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  def test_preview_sets_private_cache_and_does_not_404
    response = FakeResponse.new

    assert_equal :preview, RecordingStudioPresskits::Visibility.apply_public_response!(
      presentation: :preview,
      response: response
    )
    assert_equal 200, response.status
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  def test_fragment_cache_key_includes_presentation
    kit = FakeKit.new("kit-1", "PressKit", "rec-1", true)

    assert_equal ["presskits", "kit-1", :preview, "rec-1"],
                 RecordingStudioPresskits::Visibility.fragment_cache_key(kit, :preview)
  end

  def test_kit_settings_blank_fallback_is_preview
    assert_equal :preview, RecordingStudioPresskits::KitSettings.fallback_for(nil)
  end

  def test_site_name_prefers_configuration_then_i18n_then_rails
    original = RecordingStudioPresskits.configuration.site_name
    RecordingStudioPresskits.configuration.site_name = "Harbour Studio"

    assert_equal "Harbour Studio", RecordingStudioPresskits::Visibility.site_name
  ensure
    RecordingStudioPresskits.configuration.site_name = original
  end

  def test_site_name_falls_back_when_unconfigured
    original = RecordingStudioPresskits.configuration.site_name
    RecordingStudioPresskits.configuration.site_name = nil

    name = RecordingStudioPresskits::Visibility.site_name
    refute_empty name
    refute_equal "Harbour Studio", name
  ensure
    RecordingStudioPresskits.configuration.site_name = original
  end

  def test_registration_path_is_blank_by_default
    original = RecordingStudioPresskits.configuration.registration_path
    RecordingStudioPresskits.configuration.registration_path = "  "

    assert_nil RecordingStudioPresskits::Visibility.registration_path
  ensure
    RecordingStudioPresskits.configuration.registration_path = original
  end
end
