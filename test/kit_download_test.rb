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

  def test_audience_defaults_include_registered_custom_audiences
    registry = Object.new
    registry.define_singleton_method(:names) { %i[public signed_in granted] + [:"presskits.test_custom"] }

    RecordingStudioAccessible.stub(:audience_registry, registry) do
      defaults = RecordingStudioPresskits::KitDownload.audience_defaults

      assert_includes defaults[:allowed], :"presskits.test_custom"
    end
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
    assert_includes editor, 'icon: "arrow-down-tray"'
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
    assert_includes locale, 'public: "globe-alt"'
    assert_includes locale, 'signed_in: "user"'
    assert_includes locale, 'granted: "lock-closed"'
    assert_includes locale, 'default: "user-group"'
  end

  def test_audience_icons_use_defaults_config_and_i18n
    icons = RecordingStudioPresskits::KitDownload
    previous = RecordingStudioPresskits.configuration.download_audience_icons
    RecordingStudioPresskits.configuration.download_audience_icons = {}

    assert_equal "globe-alt", icons.audience_icon_for(:public)
    assert_equal "user", icons.audience_icon_for(:signed_in)
    assert_equal "lock-closed", icons.audience_icon_for(:granted)
    assert_equal "user-group", icons.audience_icon_for(:"presskits.test_custom")

    I18n.backend.store_translations(
      :en,
      recording_studio_presskits: { downloads: { audience_icons: { granted: "key" } } }
    )

    assert_equal "key", icons.audience_icon_for(:granted)

    RecordingStudioPresskits.configuration.download_audience_icons = { granted: "sparkles" }

    assert_equal "sparkles", icons.audience_icon_for(:granted)
    assert_equal "globe-alt", icons.audience_icon_for(:public)
  ensure
    RecordingStudioPresskits.configuration.download_audience_icons = previous
    I18n.backend.store_translations(
      :en,
      recording_studio_presskits: {
        downloads: {
          audience_icons: {
            public: "globe-alt",
            signed_in: "user",
            granted: "lock-closed",
            default: "user-group"
          }
        }
      }
    )
  end

  def test_downloads_editor_uses_inline_radio_group
    root = File.expand_path("..", __dir__)
    editors = "#{root}/app/components/recording_studio_presskits/press_kits"
    component = File.read("#{editors}/downloads_editor_component.html.erb")
    ruby = File.read("#{editors}/downloads_editor_component.rb")
    helper = File.read("#{root}/app/helpers/recording_studio_presskits/kit_editor_helper.rb")
    controller = File.read("#{root}/app/controllers/recording_studio_presskits/kit_downloads_controller.rb")
    screen = File.read("#{root}/app/views/recording_studio_presskits/kit_downloads/edit.html.erb")
    routes = File.read("#{root}/config/routes.rb")

    assert_includes routes, 'resource :downloads, only: %i[edit update], controller: "kit_downloads"'
    assert_includes controller, "KitDownload.set_audience!"
    assert_includes controller, "authorize_recording!(@press_kit_recording, role: :edit)"
    assert_includes ruby, "KitDownload.audience_icon_for(audience)"
    assert_includes component, 'name: "downloads[audience]"'
    assert_includes component, "variant: :inline"
    assert_includes component, "RadioGroup::Component"
    refute_includes component, "Select::Component"
    assert_includes component, "max-w-xl"
    assert_includes component, "downloads.constrained"
    assert_includes component, "downloads.audience_label"
    assert_includes helper, "presskits_editor_blank_chrome_title"
    assert_includes screen, "flat_pack_modal_screen"
    assert_includes screen, "presskits_editor_modal_id"
    assert_includes screen, "presskits_editor_blank_chrome_title"
    assert_includes screen, "downloads.title"
    assert_includes screen, "downloads.subtitle"
    refute_includes screen, "flat_pack_modal_screen(modal_id: presskits_editor_modal_id, title: I18n.t"
  end
end
