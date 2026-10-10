# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/kit_download"

class KitDownloadTest < Minitest::Test
  def test_action_and_scope_are_public_kit_download
    assert_equal :"presskits.kit_download", RecordingStudioPresskits::KitDownload::ACTION
    assert_equal :public, RecordingStudioPresskits::KitDownload::EXPORT_SCOPE
    assert_equal "kit.txt", RecordingStudioPresskits::KitDownload::TEXT_FILENAME
  end

  def test_audience_defaults_are_public_and_editable
    defaults = RecordingStudioPresskits::KitDownload.audience_defaults

    assert_includes defaults[:allowed], :public
    assert_includes defaults[:allowed], :signed_in
    assert_includes defaults[:allowed], :granted
    assert_equal :public, defaults[:default]
    assert_equal %i[download edit admin], defaults[:granted_roles]
    refute_includes defaults[:granted_roles], :view
    assert_equal true, defaults[:granted_override]
    assert_equal :edit, defaults[:manage_role]
  end

  def test_filenames_sanitize_and_uniquify
    names = RecordingStudioPresskits::KitDownload::Filenames.new

    assert_equal "harbour-gallery.jpg", names.unique("harbour gallery.jpg")
    assert_equal "harbour-gallery-2.jpg", names.unique("harbour-gallery.jpg")
    assert_equal "harbour-gallery-3.jpg", names.unique("cover/harbour-gallery.jpg")
    assert_equal "file", names.unique("...")
  end

  def test_press_kit_opts_into_manifest_downloadable
    source = File.read(File.expand_path("../app/models/recording_studio_presskits/press_kit.rb", __dir__))

    assert_includes source, "RecordingStudio::Capabilities::Downloadable.to"
    assert_includes source, "source: :manifest"
    assert_includes source, "format: :zip"
    assert_includes source, "action: KitDownload::ACTION"
    assert_includes source, "export_scope: KitDownload::EXPORT_SCOPE"
    assert_includes source, "def downloadable_manifest"
    assert_includes source, "def downloadable_available_for?"
    assert_includes source, "enable_capability(:action_audiences"
  end

  def test_engine_subscribes_after_initialize
    engine = File.read(File.expand_path("../lib/recording_studio_presskits/engine.rb", __dir__))

    assert_includes engine, "recording_studio_presskits.require_downloadable"
    assert_includes engine, "recording_studio_presskits.kit_download"
    assert_includes engine, "KitDownload.configure_audience!"
    assert_includes engine, "KitDownload.subscribe!"
  end

  def test_public_kit_renders_downloadable_button_helper
    html_path = "../app/components/recording_studio_presskits/press_kits/public_show_component.html.erb"
    html = File.read(File.expand_path(html_path, __dir__))
    component_path = "../app/components/recording_studio_presskits/press_kits/public_show_component.rb"
    component = File.read(File.expand_path(component_path, __dir__))

    assert_includes html, "presskits-kit-download"
    assert_includes html, "recording_studio_downloadable_button"
    assert_includes html, "show_download?"
    assert_includes component, "return false if preview?"
    assert_includes component, "KitDownload.allowed?"
    editor = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/kit_editor_component.html.erb", __dir__)
    )
    refute_includes editor, "presskits-kit-download"
    assert_includes editor, 'id: "presskits-downloads"'
    assert_includes editor, "download_edit_path"
  end

  def test_download_copy_is_i18n
    locale = File.read(File.expand_path("../config/locales/recording_studio_presskits.en.yml", __dir__))

    assert_includes locale, "Download kit"
    assert_includes locale, "Getting it ready"
    assert_includes locale, "Try again"
    assert_includes locale, "Company"
    assert_includes locale, "Location"
    assert_includes locale, "Who can download this press kit"
    assert_includes locale, 'downloads: "Downloads"'
    assert_includes locale, "Your workspace only allows some of these choices"
  end

  def test_downloads_editor_uses_accessible_select
    component = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/downloads_editor_component.html.erb", __dir__)
    )
    ruby = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/downloads_editor_component.rb", __dir__)
    )
    controller = File.read(
      File.expand_path("../app/controllers/recording_studio_presskits/kit_downloads_controller.rb", __dir__)
    )
    routes = File.read(File.expand_path("../config/routes.rb", __dir__))
    screen = File.read(
      File.expand_path("../app/views/recording_studio_presskits/kit_downloads/edit.html.erb", __dir__)
    )

    assert_includes routes, 'resource :downloads, only: %i[edit update], controller: "kit_downloads"'
    assert_includes controller, "KitDownload.set_audience!"
    assert_includes controller, "authorize_recording!(@press_kit_recording, role: :edit)"
    assert_includes ruby, "{ label: option[:label], value: option[:audience].to_s }"
    assert_includes component, 'name: "downloads[audience]"'
    assert_includes component, "max-w-xl"
    assert_includes component, "downloads.constrained"
    assert_includes screen, "flat_pack_modal_screen"
    assert_includes screen, "pk-editor"
    assert_includes screen, "downloads.title"
    assert_includes screen, "downloads.subtitle"
  end
end
