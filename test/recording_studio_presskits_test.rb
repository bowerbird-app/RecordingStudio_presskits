# frozen_string_literal: true

require "test_helper"

class RecordingStudioPresskitsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.5.0", ::RecordingStudioPresskits::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPresskits::Engine
  end

  def test_gemspec_pins_recording_studio_and_accessible
    gemspec = File.read(File.expand_path("../recording_studio_presskits.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.6"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_admin", "~> 2.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_orderable", "~> 0.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_duplicatable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "flat_pack", ">= 0.1.133"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_publishable"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_attachable"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_api"'
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.133"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"'
    refute_includes gemfile, "recording_studio/v3.0.0"
    refute_includes gemfile, 'tag: "v0.6.0"'
    refute_includes gemfile, 'tag: "v0.1.134"'
    refute_includes gemfile, 'tag: "0.3.1"'
  end

  def test_does_not_ship_copied_core_hooks_or_template_leftovers
    refute File.exist?(File.expand_path("../lib/recording_studio_presskits/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_presskits/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_presskits/services/example_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_presskits/capabilities/example.rb", __dir__))
    refute File.exist?(File.expand_path("../app/controllers/recording_studio_presskits/home_controller.rb", __dir__))
  end

  def test_press_kit_declares_product_label_and_host_root_parent
    source = File.read(File.expand_path("../app/models/recording_studio_presskits/press_kit.rb", __dir__))

    assert_includes source, 'self.table_name = "recording_studio_press_kits"'
    assert_includes source, 'label: "Press kit"'
    assert_includes source, "root: false"
    assert_includes source, "allowed_parent_types: [RecordingStudioPresskits.parent_root_type]"
    assert_includes source, "include RecordingStudio::Capabilities::Orderable.to"
    assert_includes source, "include RecordingStudio::Capabilities::Trashable.to"
    assert_includes source, "RecordingStudio::Capabilities::Duplicatable.to"
    assert_includes source, 'suffix: " (Copy)"'
    assert_includes source, "exclude_children: []"
    refute_includes source, "include_children: true"
    refute_includes source, ".with("
    refute_includes source, ".enabled"
    refute_includes source, "RecordingStudioDuplicatable::Capabilities"
    refute_includes source, "Recordable"
    refute_match(/label:\s*"[^"]*Recordable/, source)
    refute_includes source, "enable_capability(:orderable"
    refute_includes source, "enable_capability(:trashable"
    refute_includes source, "enable_capability(:duplicatable"
  end

  def test_picker_helper_uses_core_public_parent_apis
    source = File.read(File.expand_path("../lib/recording_studio_presskits.rb", __dir__))

    assert_includes source, "def press_kit_type_name"
    assert_includes source, "def picker_types"
    assert_includes source, "RecordingStudio.recordable_type_name"
    assert_includes source, "RecordingStudio.allowed_parent_types_for"
    refute_includes source, "Block"
    refute_includes source, "Slot"
  end

  def test_dummy_app_uses_recording_studio_default_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    default_layout = File.read(
      File.expand_path("dummy/app/views/layouts/recording_studio/default_layout.html.erb", __dir__)
    )

    assert_includes controller_source, "include RecordingStudio::UsesDefaultLayout"
    assert_includes controller_source, '"recording_studio/default_layout"'
    assert_includes controller_source, 'devise_controller? ? "application"'
    assert_includes default_layout, '<html data-theme="rounded">'
    assert_includes default_layout, "page_nav_options[:anchor_href]"
    refute_includes default_layout, "page_nav_options[:anchor_url]"
    refute_includes controller_source, "flat_pack_sidebar"
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
  end

  def test_dummy_mounts_mixin_engines
    routes = File.read(File.expand_path("dummy/config/routes.rb", __dir__))

    assert_includes routes, 'mount RecordingStudioOrderable::Engine, at: "/recording_studio_orderable"'
    assert_includes routes, 'mount RecordingStudioTrashable::Engine, at: "/recording_studio_trashable"'
    assert_includes routes, 'mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"'
    assert_includes routes, 'mount RecordingStudioPresskits::Engine, at: "/recording_studio_presskits"'
    assert_includes routes, 'recording_studio_admin_for :admin, at: "/admin", root_section: :press_kits'
    refute_includes routes, "recording_studio_publishable"
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))
    sources_task = File.read(File.expand_path("dummy/lib/tasks/tailwind_bundle_sources.rake", __dir__))

    assert_includes tailwind_source, '@import "./bundle_sources.css"'
    assert_includes tailwind_source, "vendor/bundle/**/bundler/gems/flatpack-*/app/components/**/*.rb"
    assert_includes tailwind_source, "vendor/bundle/**/bundler/gems/RecordingStudio-*/app/views/**/*.erb"
    assert_includes sources_task, '"flat_pack"'
    assert_includes sources_task, '"recording_studio"'
    assert_includes sources_task, '"recording_studio_orderable"'
    assert_includes sources_task, '"recording_studio_trashable"'
    assert_includes sources_task, '"recording_studio_duplicatable"'
    assert_includes sources_task, '"recording_studio_admin"'
    assert_includes sources_task, '"recording_studio_presskits"'
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
  end

  def test_recording_studio_registers_press_kit_with_strict_declarations
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, '"RecordingStudioPresskits::PressKit"'
    assert_includes initializer_source, '"FakeBlock"'
    assert_includes initializer_source, '"AdminRoot"'
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to prove Recording Studio Press Kits"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "redirects to the press kit index"
    refute_includes readme_source, "flat_pack_sidebar"
    refute_includes readme_source, "/docs/"
  end

  def test_product_readme_is_the_press_kit_guide
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "Recording Studio Press Kits"
    assert_includes readme, "v4.2.0"
    assert_includes readme, "v0.6.1"
    assert_includes readme, "tag: \"2.0.0\""
    assert_includes readme, "tag: \"0.2.0\""
    assert_includes readme, "tag: \"0.4.0\""
    assert_includes readme, "Press kit"
    assert_includes readme, "RecordingStudioPresskits::PressKit"
    assert_includes readme, "recording_studio_orderable_reorder!"
    assert_includes readme, "recording_studio_trashable_trash!"
    assert_includes readme, "duplicate_in_place!"
    refute_includes readme, "v3 declarations"
    refute_includes readme, "RecordingStudio v3"
    refute_includes readme, "ExampleService"
    refute_includes readme, "internal template"
    refute_includes readme, "recording_studio/v3.0.0"
  end

  def test_dummy_root_is_the_press_kit_slice
    routes = File.read(File.expand_path("dummy/config/routes.rb", __dir__))
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)

    assert_includes routes, 'root to: redirect("/recording_studio_presskits")'
    refute File.exist?(view_path)
    refute File.exist?(File.expand_path("dummy/app/controllers/home_controller.rb", __dir__))
  end

  def test_dummy_does_not_ship_starter_docs
    refute File.exist?(File.expand_path("dummy/app/controllers/docs_controller.rb", __dir__))
    assert_empty Dir[File.expand_path("dummy/app/views/docs/**/*.erb", __dir__)]
  end

  def test_engine_ships_press_kit_screens
    view_path = File.expand_path("../app/views/recording_studio_presskits/press_kits/index.html.erb", __dir__)

    assert File.exist?(view_path)
    refute File.exist?(File.expand_path("../app/controllers/recording_studio_presskits/home_controller.rb", __dir__))
  end

  def test_dummy_fake_block_is_host_only
    refute File.exist?(File.expand_path("../app/models/recording_studio_presskits/fake_block.rb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/models/fake_block.rb", __dir__))

    source = File.read(File.expand_path("dummy/app/models/fake_block.rb", __dir__))
    assert_includes source, 'label: "Fake block"'
    assert_includes source, 'allowed_parent_types: ["RecordingStudioPresskits::PressKit"]'
    assert_includes source, "include RecordingStudio::Capabilities::Trashable.to"
    refute_includes source, "Capabilities::Orderable"
    refute_includes source, "Capabilities::Duplicatable"
    refute_includes source, ".with("
    refute_includes source, ".enabled"
  end

  def test_dummy_workspace_enables_orderable_for_press_kits_only
    source = File.read(File.expand_path("dummy/app/models/workspace.rb", __dir__))

    assert_includes source, "RecordingStudio.enable_capability(:accessible, on: self)"
    assert_includes source, "Capabilities::Orderable.to(allows:"
    assert_includes source, '"RecordingStudioPresskits::PressKit"'
    refute_includes source, "if defined?(RecordingStudioAccessible)"
    refute_includes source, "Capabilities::Trashable"
    refute_includes source, "Capabilities::Duplicatable"
    refute_includes source, ".with("
    refute_includes source, ".enabled"
  end

  def test_engine_registers_admin_list_section
    section = File.read(File.expand_path("../lib/recording_studio_presskits/admin/press_kits_section.rb", __dir__))
    widget = File.read(File.expand_path("../lib/recording_studio_presskits/admin/press_kits_list_widget.rb", __dir__))

    assert_includes section, 'key "press_kits"'
    assert_includes section, 'widget "widgets.press_kits.list"'
    refute_includes section, "published"
    refute_includes widget, "type :number"
    assert_includes widget, "type :list"
    assert_includes widget, "KitQuery.live_kits"
    refute_includes widget, "Publishable"

    query = File.read(File.expand_path("../lib/recording_studio_presskits/kit_query.rb", __dir__))
    assert_includes query, "recording_studio_trashable_active"
    assert_includes query, "def live_children"
    assert_includes query, "def live_child"
  end

  def test_user_slice_uses_segmented_buttons_and_picker
    index = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/index_component.html.erb", __dir__)
    )
    show = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/show_component.html.erb", __dir__)
    )

    assert_includes index, "FlatPack::SegmentedButtons::Component"
    assert_includes index, "FlatPack::Card::Component"
    assert_includes index, "FlatPack::Table::Component"
    assert_includes index, "FlatPack::Grid::Component"
    assert_includes index, "FlatPack::EmptyState::Component"
    assert_includes show, "FlatPack::EmptyState::Component"
    assert_includes show, "SectionPickerComponent"
    refute_includes index, "Dummy host"
  end
end
