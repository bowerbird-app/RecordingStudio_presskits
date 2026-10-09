# frozen_string_literal: true

require "test_helper"

class RecordingStudioPresskitsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.26.0", ::RecordingStudioPresskits::VERSION
  end

  def test_engine_and_dummy_keep_header_text_title_and_images_heading_migrations
    root = File.expand_path("..", __dir__)
    [
      "db/migrate/20261005120000_add_description_to_recording_studio_press_kits.rb",
      "db/migrate/20261006120000_add_title_to_recording_studio_texts.rb",
      "db/migrate/20261006140000_replace_images_caption_with_title_and_subtitle.rb",
      "db/migrate/20261006160000_introduce_recording_studio_kit_sections.rb",
      "db/migrate/20261007120000_create_recording_studio_video_sections.rb",
      "db/migrate/20261008120000_create_recording_studio_credits.rb",
      "db/migrate/20261008180000_create_recording_studio_facts.rb",
      "db/migrate/20261009120000_add_cover_to_recording_studio_press_kits.rb",
      "test/dummy/db/migrate/20261005120000_add_description_to_recording_studio_press_kits.rb",
      "test/dummy/db/migrate/20261006120000_add_title_to_recording_studio_texts.rb",
      "test/dummy/db/migrate/20261006140000_replace_images_caption_with_title_and_subtitle.rb",
      "test/dummy/db/migrate/20261006160000_introduce_recording_studio_kit_sections.rb",
      "test/dummy/db/migrate/20261007120000_create_recording_studio_video_sections.rb",
      "test/dummy/db/migrate/20261008120000_create_recording_studio_credits.rb",
      "test/dummy/db/migrate/20261008180000_create_recording_studio_facts.rb",
      "test/dummy/db/migrate/20261009120000_add_cover_to_recording_studio_press_kits.rb",
      "test/dummy/db/migrate/20261006143000_create_recording_studio_videos.rb"
    ].each do |path|
      assert File.exist?(File.join(root, path)), path
    end

    refute File.exist?(File.join(root, "db/migrate/20261006143000_create_recording_studio_videos.rb"))
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPresskits::Engine
  end

  def test_gemspec_pins_recording_studio_and_accessible
    gemspec = File.read(File.expand_path("../recording_studio_presskits.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.12"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_admin", "~> 2.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_orderable", "~> 0.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.5"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_duplicatable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "flat_pack", ">= 0.1.222"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_publishable", "~> 0.5"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_attachable", "~> 0.12"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_external_embed", "~> 0.1.1"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_video", "~> 0.1.0"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_api"'
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.3.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.12.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "v2.0.7"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.6"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.222"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.7"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.5"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.12.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.4"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.1"'
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
    refute File.exist?(
      File.expand_path("../app/javascript/recording_studio_presskits/controllers/editor_modal_controller.js", __dir__)
    )
    refute File.exist?(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/editor_modal_component.rb", __dir__)
    )
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
    assert_includes source, "RecordingStudio::Capabilities::Publishable.to"
    assert_includes source, 'public_controller: "recording_studio_presskits/public_press_kits"'
    assert_includes source, "public_action: :show"
    assert_includes source, 'public_layout: "recording_studio_presskits/blank"'
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
    assert_includes source, "def register_section"
    assert_includes source, "def section_types"
    assert_includes source, "def section?"
    assert_includes source, "RecordingStudio.recordable_type_name"
    assert_includes source, "RecordingStudio.declared_allowed_parent_types_for"
    assert_includes source, "excluded_picker_types"
    refute_includes source, "Block"
    refute_includes source, "Slot"
  end

  def test_api_registers_section_actions_without_a_bare_create
    source = File.read(File.expand_path("../lib/recording_studio_presskits/api.rb", __dir__))

    assert_includes source, "capability_actions: %i[create_section reorder_sections]"
    assert_includes source, "capability_actions: %i[remove_section]"
    assert_includes source, "operations: %i[show update]"
    assert_includes source, "output_keys: %i[title description cover_style cover_color cover_text_color]"
    assert_includes source, "writable_attributes: %i[cover_style cover_color cover_text_color]"
    assert_includes source, "operations: %i[index show update]"
    assert_includes source, "register_section_actions"
    refute_includes source, "operations: %i[create"
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
    refute_includes controller_source, "Sign out"
    refute_includes controller_source, "Sign in"
    dummy_helper = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))
    refute_includes dummy_helper, "presskits_extra_nav"
    refute_includes dummy_helper, "Sign out"
    refute_includes default_layout, "Sign out"
    refute_includes default_layout, "Sign in"
    refute_includes default_layout, "root_switch"
    assert_includes default_layout, '<html data-theme="rounded">'
    assert_includes default_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes default_layout, "page_nav_options[:anchor_href]"
    refute_includes default_layout, "secondary_anchor_href"
    assert_includes default_layout, "One back control from this layout"
    assert_includes default_layout, "back_url.blank?"
    assert_includes default_layout, "anchor_tooltip:"
    refute_includes default_layout, "page_nav_options[:anchor_url]"
    refute_includes default_layout, "page_nav_options[:back_url]"
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
    assert_includes routes, 'mount RecordingStudioPublishable::Engine, at: "/"'
    assert_includes routes, 'recording_studio_admin_for :admin, at: "/admin", root_section: :press_kits'
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
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
    refute_includes sources_task, "flatpack_fieldset"
    refute_includes tailwind_source, "flatpack_fieldset"
    assert_includes sources_task, '"recording_studio_publishable"'
    assert_includes sources_task, '"recording_studio_attachable"'
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
  end

  def test_recording_studio_registers_press_kit_with_strict_declarations
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, '"RecordingStudioPresskits::PressKit"'
    assert_includes initializer_source, '"RecordingStudioPresskits::KitSection"'
    assert_includes initializer_source, '"RecordingStudioPresskits::Text"'
    assert_includes initializer_source, '"RecordingStudioPresskits::Images"'
    assert_includes initializer_source, '"FakeBlock"'
    presskits_initializer = File.read(
      File.expand_path("dummy/config/initializers/recording_studio_presskits.rb", __dir__)
    )
    assert_includes presskits_initializer, "excluded_picker_types"
    assert_includes presskits_initializer, "register_section("
    assert_includes presskits_initializer, '"FakeBlock"'
    assert_includes initializer_source, '"AdminRoot"'
    assert_includes initializer_source, '"RecordingStudioPublishable::Publishable"'
    assert_includes initializer_source, '"RecordingStudioAttachable::Library"'
    assert_includes initializer_source, '"RecordingStudioAttachable::Placement"'
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
    assert_includes readme, "v4.3.0"
    assert_includes readme, "v0.12.1"
    assert_includes readme, "tag: \"v2.0.7\""
    assert_includes readme, "tag: \"v0.2.7\""
    assert_includes readme, "tag: \"v0.5.0\""
    assert_includes readme, "tag: \"v0.4.5\""
    assert_includes readme, "tag: \"v0.1.222\""
    assert_includes readme, 'gem "flat_pack", ">= 0.1.222"'
    assert_includes readme, "FlatPack::Modal::Component"
    assert_includes readme, "navigable: true"
    assert_includes readme, "flat_pack_modal_screen"
    assert_includes readme, "pk-editor"
    assert_includes readme, 'data-turbo-frame="_top"'
    assert_includes readme, "Edit heading"
    assert_includes readme, "Edit title"
    assert_includes readme, "Section actions"
    assert_includes readme, "FlatPack::Fab::Component"
    assert_includes readme, "variant: :swatches"
    refute_includes readme, "named radios"
    assert_includes readme, "Edit content"
    refute_includes readme, "Section settings"
    refute_includes readme, "FlatPack::Fieldset::Component"
    assert_includes readme, "unsaved-changes controller"
    assert_includes readme, "PressKit.indexable"
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
    public_controller = File.read(
      File.expand_path("../app/controllers/recording_studio_presskits/public_press_kits_controller.rb", __dir__)
    )
    public_show = File.read(
      File.expand_path("../app/views/recording_studio_presskits/public_press_kits/show.html.erb", __dir__)
    )

    assert File.exist?(view_path)
    assert File.exist?(File.expand_path("../app/views/recording_studio_presskits/press_kits/edit.html.erb", __dir__))
    refute File.exist?(File.expand_path("../app/controllers/recording_studio_presskits/home_controller.rb", __dir__))
    refute_includes public_controller, "UsesDefaultLayout"
    refute_includes public_controller, "Sign in"
    assert_includes public_show, "content_for :title"
    refute_includes public_show, "recording_studio_page_nav"
    refute_includes public_show, "page_nav"
    refute_includes public_show, "Sign in"
    blank_layout = File.read(
      File.expand_path("../app/views/layouts/recording_studio_presskits/blank.html.erb", __dir__)
    )
    assert_includes blank_layout, 'stylesheet_link_tag "flat_pack/application"'

    helper = File.read(File.expand_path("../app/helpers/recording_studio_presskits/application_helper.rb", __dir__))
    assert_includes helper, "recording_studio_accessible_avatars"
    refute_includes helper, "root_switch"
    refute_includes helper, "Sign out"
    refute_includes helper, "presskits_extra_nav"
  end

  def test_dummy_fake_block_is_host_only
    refute File.exist?(File.expand_path("../app/models/recording_studio_presskits/fake_block.rb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/models/fake_block.rb", __dir__))

    source = File.read(File.expand_path("dummy/app/models/fake_block.rb", __dir__))
    assert_includes source, 'label: "Fake block"'
    assert_includes source, 'allowed_parent_types: ["RecordingStudioPresskits::KitSection"]'
    assert_includes source, "include RecordingStudio::Capabilities::Trashable.to"
    refute_includes source, "Capabilities::Orderable"
    refute_includes source, "Capabilities::Duplicatable"
    refute_includes source, "Capabilities::Publishable"
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
    published = File.read(
      File.expand_path("../lib/recording_studio_presskits/admin/press_kits_published_widget.rb", __dir__)
    )
    unpublished = File.read(
      File.expand_path("../lib/recording_studio_presskits/admin/press_kits_unpublished_widget.rb", __dir__)
    )

    assert_includes section, 'key "press_kits"'
    assert_includes section, 'widget "widgets.press_kits.published"'
    assert_includes section, 'widget "widgets.press_kits.unpublished"'
    refute_includes section, "widgets.press_kits.list"
    refute_includes published, "type :number"
    refute_includes unpublished, "type :number"
    assert_includes published, "type :list"
    assert_includes unpublished, "type :list"
    assert_includes published, "KitQuery.published_kits"
    assert_includes unpublished, "KitQuery.unpublished_kits"

    query = File.read(File.expand_path("../lib/recording_studio_presskits/kit_query.rb", __dir__))
    assert_includes query, "recording_studio_trashable_active"
    assert_includes query, "def sections_for"
    assert_includes query, "def section_content"
    assert_includes query, "section_types"
    refute_includes query, "RecordingStudioPublishable::Publishable"
    assert_includes query, "def section_for"
    assert_includes query, "def published_kits"
    assert_includes query, "PressKit.indexable"
    assert_includes query, "def unpublished_kits"
  end

  def test_user_slice_uses_button_group_and_picker
    index = File.read(
      File.expand_path("../app/components/recording_studio_presskits/press_kits/index_component.html.erb", __dir__)
    )
    components = File.expand_path("../app/components/recording_studio_presskits", __dir__)
    show = File.read(File.expand_path("press_kits/kit_editor_component.html.erb", components))

    assert_includes index, 'title: "My presskits"'
    assert_includes index, 'text: "Presskit"'
    assert_includes index, 'icon: "plus"'
    assert_match(/Presskit.*FlatPack::ButtonGroup::Component/m, index)
    assert_includes index, "FlatPack::ButtonGroup::Component"
    assert_includes index, "icon_only: true"
    assert_includes index, "squares-2x2"
    assert_includes index, "table-cells"
    refute_includes index, "FlatPack::SegmentedButtons::Component"
    refute_includes index, "justify-between"
    refute_includes index, 'text: "Cards"'
    refute_includes index, 'text: "Table"'
    assert_includes index, "RecordingStudioPresskits::Cover::Component"
    assert_includes index, "size: :card"
    cover = File.read(File.expand_path("cover/component.rb", components))
    cover_html = File.read(File.expand_path("cover/component.html.erb", components))
    assert_includes cover, "9 / 16"
    assert_includes cover, "21 / 9"
    assert_includes cover, "aspect-[9/16]"
    assert_includes cover_html, "--page-title-h1-size"
    assert_includes cover_html, "variant: heading_variant"
    refute_includes index, "card.media"
    refute_includes index, 'name: "photo"'
    refute_includes index, "presskits_cover_url_for"
    assert_includes index, "FlatPack::Table::Component"
    assert_includes index, "FlatPack::Grid::Component"
    assert_includes index, "FlatPack::EmptyState::Component"
    header = File.read(File.expand_path("press_kits/header_editor_component.html.erb", components))
    kit_header = File.read(File.expand_path("press_kits/kit_header_component.html.erb", components))

    assert_includes show, "SectionPickerComponent"
    assert_includes show, "render_publishable_quick_actions"
    assert_includes show, "SectionsOrderComponent"
    assert_includes show, "FlatPack::Card::Component"
    assert_includes show, 'id="presskits-editor-toolbar"'
    assert_includes show, 'id="presskits-editor-preview"'
    assert_includes show, "KitHeaderComponent"
    assert_includes show, "EditableSectionComponent"
    assert_includes show, "navigable: true"
    refute_includes show, "SectionDropdownComponent"
    refute_includes show, "view_public"
    assert_includes kit_header, "presskits_editor_open_data"
    heading_editor = File.read(File.expand_path("press_kits/section_heading_editor_component.html.erb", components))
    helper = File.read(File.expand_path("../app/helpers/recording_studio_presskits/kit_editor_helper.rb", __dir__))

    assert_includes helper, "presskits_editor_save_data"
    assert_includes helper, 'data[:turbo_frame] = "_top"'
    assert_includes heading_editor, "presskits_editor_save_data"
    refute_includes show, 'turbo_frame: "presskits-editor-dialog"'
    refute_includes show, "EditorModalComponent"
    refute_includes show, "md:grid-cols-2"
    refute_includes show, 'name: "press_kit[title]"'
    refute_includes show, 'name: "press_kit[description]"'
    refute_includes show, 'text: "Save"'
    assert_includes kit_header, 'id="presskits-kit-header"'
    assert_includes kit_header, "Cover::Component"
    assert_includes kit_header, "FlatPack::Fab::Component"
    assert_includes kit_header, "contained: true"
    assert_includes kit_header, "position: :top_right"
    assert_includes kit_header, "backdrop: false"
    assert_includes kit_header, "size: :sm"
    assert_includes kit_header, "edit_heading_label"
    assert_includes kit_header, "cover_colours_label"
    refute_includes kit_header, "arrows-up-down"
    refute_includes kit_header, "trash"
    section = File.read(File.expand_path("press_kits/editable_section_component.html.erb", components))
    assert_includes section, "FlatPack::Fab::Component"
    assert_includes section, "contained: true"
    assert_includes section, "position: :top_right"
    assert_includes section, "backdrop: false"
    assert_includes section, "size: :sm"
    assert_includes section, "style: :danger"
    assert_includes section, "edit_title_label"
    assert_includes section, "edit_content_label"
    assert_includes section, "reorder_label"
    assert_includes section, "trash_label"
    assert_includes section, "add_new_section_label"
    assert_includes section, "turbo_confirm"
    assert_includes section, "SectionPickerComponent"
    refute_includes section, "SectionDropdownComponent"
    refute_includes section, "hover:outline-[var(--color-primary)]"
    refute_includes section, "p-4 -mx-4"
    assert_includes header, 'name: "press_kit[title]"'
    assert_includes header, 'name: "press_kit[description]"'
    assert_includes header, 'name: "press_kit[cover_color]"'
    assert_includes header, 'name: "press_kit[cover_text_color]"'
    assert_includes header, "Text colour"
    assert_includes header, "FlatPack::RadioGroup::Component"
    assert_includes header, "variant: :swatches"
    assert_includes header, "size: :md"
    assert_includes header, "cover_text_swatch_options"
    assert_includes header, "variant: :inline"
    assert_includes header, "FlatPack::ColorSwatch::Component"
    assert_includes header, 'id="presskits-header-colours"'
    chrome = File.read(File.expand_path("press_kits/editor_chrome.rb", components))
    assert_includes chrome, "--surface-muted-background-color"
    assert_includes chrome, "focus-visible:outline"
    assert_includes chrome, "[@media(hover:none)]"
    assert_includes chrome, "relative"
    assert_includes header, "auto_text_value"
    assert_includes header, "max_characters: RecordingStudioPresskits::PressKit::SHORT_DESCRIPTION_LIMIT"
    assert_includes header, "flat-pack--unsaved-changes"
    refute_includes header, 'text: "Cancel"'
    refute_includes header, "cols: 2"
    assert_includes header, 'id: "presskits-header-edit-preview"'
    assert_includes header, "Cover::Component"
    preview_js = File.read(File.expand_path(
                             "../app/javascript/recording_studio_presskits/controllers/cover_preview_controller.js",
                             __dir__
                           ))
    assert_includes preview_js, "heading.style.color = textColor"
    assert_includes preview_js, "subtitle.style.color = textColor"
    assert_operator header.index('name: "press_kit[title]"'), :<, header.index('id: "presskits-header-edit-preview"')
    refute_includes show, "EditButtonComponent"
    refute_includes show, "Go live"
    refute_includes show, "FlatPack::Picker::Component"
    refute_includes index, "Dummy host"
    assert_includes index, "FlatPack::SidebarLayout::Component"
    assert_includes index, "FlatPack::Sidebar::Group::Component"
    assert_includes index, 'title: "Library"'
    assert_includes index, "open: true"
    assert_includes index, 'text: "Credits"'
    assert_includes index, 'icon: "user-group"'
    assert_includes index, "@credits_path"
    assert_includes index, 'aria: { label: "Open sidebar" }'
    assert_includes index, "toggleMobile"
    assert_includes index, 'class: "md:hidden"'
    refute_match(/Button::Component\.new\(\s*text: "Credits"/m, index)
  end

  def test_credits_list_shows_the_name_and_save_sits_under_the_fields
    components = File.expand_path("../app/components/recording_studio_presskits/credits", __dir__)
    index = File.read(File.expand_path("index_component.html.erb", components))
    index_ruby = File.read(File.expand_path("index_component.rb", components))
    form = File.read(File.expand_path("form_component.html.erb", components))

    assert_includes index, 'subtitle: "People, companies and organisations that you credit in Press kits"'
    assert_includes index, 'text: "Credit"'
    assert_includes index, 'class: "w-fit"'
    assert_includes index, 'title: "Name"'
    refute_includes index, "Usual role"
    refute_includes index, 'title: "URL"'
    refute_includes index_ruby, "def usual_role"
    refute_includes index_ruby, "def url_cell"
    assert_operator form.index('name: "credit[url]"'), :<, form.index("text: button_text")
    assert_includes form, 'id: "credit-form"'
    assert_includes form, 'form: "credit-form"'
    assert_includes form, 'class: "w-fit"'
    assert_includes form, 'class="flex w-full max-w-xl items-center justify-between gap-3"'
    assert_includes form, "style: :danger"
    refute_includes form, "Divider"
  end

  def test_section_dropdown_passes_a_menu_icon
    dropdown = File.read(presskits_path(
                           "app/components/recording_studio_presskits/press_kits/section_dropdown_component.html.erb"
                         ))
    editor = File.read(presskits_path("app/components/recording_studio_presskits/press_kits/kit_editor_component.rb"))
    text = File.read(presskits_path("app/models/recording_studio_presskits/text.rb"))
    images = File.read(presskits_path("app/models/recording_studio_presskits/images.rb"))
    quotes = File.read(presskits_path("app/models/recording_studio_presskits/quote_section.rb"))
    videos = File.read(presskits_path("app/models/recording_studio_presskits/video_section.rb"))

    picker = File.read(presskits_path(
                         "app/components/recording_studio_presskits/press_kits/section_picker_component.html.erb"
                       ))
    order = File.read(presskits_path(
                        "app/components/recording_studio_presskits/press_kits/sections_order_component.html.erb"
                      ))
    orders = File.read(presskits_path("app/controllers/recording_studio_presskits/orders_controller.rb"))

    assert_includes dropdown, "icon: item[:icon]"
    assert_includes picker, "item[:description]"
    assert_includes picker, "item[:label]"
    assert_includes picker, "turbo_method: :post"
    assert_includes order, "orderable_url: @reorder_path"
    assert_includes order, 'param_uuid_name: "moving_recording_id"'
    assert_includes order, 'param_target_position_name: "target_position"'
    refute_includes order, "recording-studio-presskits--section-order"
    assert_includes orders, "recording_studio_orderable_move!"
    assert_includes orders, "moving_recording_id"
    assert_includes orders, "target_position"
    assert_includes editor, "section_menu_icon_for"
    assert_includes editor, "picker_description_for"
    assert_includes text, '"document-text"'
    assert_includes images, '"photo"'
    assert_includes quotes, '"chat-bubble-bottom-center-text"'
    assert_includes videos, '"video-camera"'
    child_path = "app/components/recording_studio_presskits/press_kits/child_component.html.erb"
    child_ruby = "app/components/recording_studio_presskits/press_kits/child_component.rb"
    child = File.read(presskits_path(child_path))
    child_component = File.read(presskits_path(child_ruby))
    assert_includes child, "icon: row_icon"
    assert_includes child, 'class: "!items-center"'
    assert_includes child, "truncate"
    assert_includes child, "title: link_title"
    refute_includes child, "arrows-up-down"
    assert_includes child_component, "def row_icon"
    assert_includes child_component, "def row_label"
    assert_includes child_component, "saved_text_title"
    assert_includes child_component, "RecordingStudioPresskits::Text"
    assert_includes child_component, "section_menu_icon"
  end

  def presskits_path(relative)
    File.expand_path("../#{relative}", __dir__)
  end

  def test_images_editor_names_title_and_subtitle
    editor = File.read(presskits_path("app/components/recording_studio_presskits/images/edit_component.html.erb"))
    component = File.read(presskits_path("app/components/recording_studio_presskits/images/edit_component.rb"))
    show = File.read(presskits_path("app/components/recording_studio_presskits/images/component.html.erb"))

    editor_path = "press_kits/section_editor_component.html.erb"
    section_editor = File.read(presskits_path("app/components/recording_studio_presskits/#{editor_path}"))

    refute_includes editor, 'name: "images[title]"'
    refute_includes editor, 'name: "images[subtitle]"'
    refute_includes editor, "images[caption]"
    heading_editor = "press_kits/section_heading_editor_component.html.erb"
    heading_view = "press_kits/section_heading_component.html.erb"
    heading = File.read(presskits_path("app/components/recording_studio_presskits/#{heading_editor}"))
    heading_display = File.read(presskits_path("app/components/recording_studio_presskits/#{heading_view}"))
    refute_includes section_editor, 'name: "kit_section[title]"'
    refute_includes section_editor, 'name: "kit_section[subtitle]"'
    assert_includes heading, 'name: "kit_section[title]"'
    assert_includes heading, 'name: "kit_section[subtitle]"'
    assert_operator heading.index('name: "kit_section[title]"'), :<,
                    heading.index('name: "kit_section[subtitle]"')
    assert_includes component, "def self.permitted_attributes\n        []"
    refute_includes show, "FlatPack::SectionTitle::Component"
    assert_includes heading_display, "FlatPack::SectionTitle::Component"
    assert_includes heading_display, "anchor_link:"
    refute_includes section_editor, 'id: "presskits-section-grid"'
    refute_includes section_editor, "cols: 2"
    assert_includes section_editor, 'id="presskits-section-fields"'
    refute_includes section_editor, 'id="presskits-section-preview"'
    refute_includes section_editor, "show_preview?"
    refute_includes section_editor, "def self.preview?"
    refute_includes section_editor, "if form?"
    refute_includes component, "def self.preview?"
    refute_includes component, "preview_card_title"
    assert_includes component, "def self.below?"
    assert_includes editor, 'text: "Upload"'
    assert_operator editor.index("flex flex-wrap items-center gap-3"), :<, editor.index('text: "Upload"')
    assert_includes editor, "upload_form_data(helpers)"
    refute_includes section_editor, "upload_form_data"
  end

  def test_section_heading_editor_is_shared_and_content_editors_omit_title_fields
    editor_path = "press_kits/section_editor_component.html.erb"
    section_editor = File.read(presskits_path("app/components/recording_studio_presskits/#{editor_path}"))
    heading_editor = "press_kits/section_heading_editor_component.html.erb"
    heading = File.read(presskits_path("app/components/recording_studio_presskits/#{heading_editor}"))
    component_path = "press_kits/section_editor_component.rb"
    component = File.read(presskits_path("app/components/recording_studio_presskits/#{component_path}"))
    engine = File.read(presskits_path("lib/recording_studio_presskits/engine.rb"))
    quotes = File.read(presskits_path("app/components/recording_studio_presskits/quote_section/edit_component.rb"))
    text = File.read(presskits_path("app/components/recording_studio_presskits/text/edit_component.rb"))

    refute_includes section_editor, "FlatPack::Tabs::Component.new"
    refute_includes section_editor, 'label: "Section title"'
    refute_includes section_editor, 'name: "kit_section[title]"'
    refute_includes heading, "Section settings"
    refute_includes heading, "Fieldset"
    refute_includes engine, "install_fieldset_fallback"
    refute_includes engine, "flatpack_fieldset"
    refute File.file?(presskits_path("lib/recording_studio_presskits/flatpack_fieldset.rb"))
    assert_operator section_editor.index("fields_in_form?"), :<, section_editor.index("section_actions")
    assert_operator section_editor.index("section_actions"), :<, section_editor.index("below_editor?")
    assert_includes section_editor, 'id: "presskits-section-content-form"'
    assert_includes heading, 'id: "presskits-section-title-form"'
    assert_includes heading, "presskits_editor_save_data.merge(controller: \"flat-pack--unsaved-changes\")"
    assert_operator heading.index('name: "kit_section[title]"'), :<,
                    heading.index('name: "kit_section[subtitle]"')
    assert_operator heading.index('name: "kit_section[subtitle]"'), :<,
                    heading.index('id="presskits-section-update"')
    assert_includes section_editor, 'id="presskits-section-content-update"'
    assert_includes component, "def update_button"
    assert_includes component, "style: :default"
    assert_includes component, '"flat-pack--unsaved-changes-target": "submit"'
    assert_includes component, 'text: "Update"'
    refute_includes component, "style: :primary"
    assert_includes component, "def fields_in_form?"
    assert_includes component, "def below_editor?"
    refute_includes component, "def form?"
    assert_includes quotes, "def below?"
    refute_includes quotes, "def form?"
    refute_includes quotes, "def self.form?"
    refute_includes text, "def self.below?"
  end

  def test_section_heading_falls_back_to_the_content_type
    source = File.read(presskits_path("lib/recording_studio_presskits.rb"))
    frame_path = "app/components/recording_studio_presskits/press_kits/section_frame_component.rb"
    editor_path = "app/components/recording_studio_presskits/press_kits/section_editor_component.html.erb"
    helper_path = "app/helpers/recording_studio_presskits/application_helper.rb"
    frame = File.read(presskits_path(frame_path))
    heading_editor = "press_kits/section_heading_editor_component.html.erb"
    heading_ruby = "press_kits/section_heading_editor_component.rb"
    heading = File.read(presskits_path("app/components/recording_studio_presskits/#{heading_editor}"))
    heading_component = File.read(presskits_path("app/components/recording_studio_presskits/#{heading_ruby}"))
    helper = File.read(presskits_path(helper_path))

    assert_includes source, "def section_heading"
    assert_includes source, "def default_section_heading"
    assert_operator source.index("def section_heading"), :<, source.index("default_section_heading")
    assert_includes frame, "RecordingStudioPresskits.section_heading"
    assert_includes frame, "def saved_title"
    assert_includes frame, "def content_visible?"
    assert_includes heading, "placeholder: section_title_fallback"
    assert_includes heading_component, "def section_title_fallback"
    assert_includes heading_component, "RecordingStudioPresskits.default_section_heading"
    assert_includes helper, "RecordingStudioPresskits.section_heading"
    refute_includes File.read(presskits_path(editor_path)), "placeholder: section_title_fallback"
  end

  def test_text_editor_names_title_and_body
    editor = File.read(
      File.expand_path("../app/components/recording_studio_presskits/text/edit_component.html.erb", __dir__)
    )
    component = File.read(
      File.expand_path("../app/components/recording_studio_presskits/text/edit_component.rb", __dir__)
    )
    show = File.read(
      File.expand_path("../app/components/recording_studio_presskits/text/component.html.erb", __dir__)
    )

    editor_path = "press_kits/section_editor_component.html.erb"
    section_editor = File.read(presskits_path("app/components/recording_studio_presskits/#{editor_path}"))

    refute_includes editor, 'name: "text[title]"'
    assert_includes editor, 'label: "Body"'
    assert_includes editor, 'name: "text[body]"'
    refute_includes section_editor, 'label: "Title"'
    refute_includes section_editor, 'name: "kit_section[title]"'
    refute_includes section_editor, "cols: 2"
    refute_includes section_editor, 'text: "Cancel"'
    actions = File.read(presskits_path(
                          "app/components/recording_studio_presskits/quote_section/actions_component.html.erb"
                        ))
    refute_includes actions, 'text: "Cancel"'
    assert_includes component, "%i[body]"
    refute_includes component, "def self.preview?"
    refute_includes show, "FlatPack::SectionTitle::Component"
    refute_includes show, "gap-4"
  end

  def test_credits_section_edits_lines_in_a_collection_editor
    editor = File.read(presskits_path(
                         "app/components/recording_studio_presskits/credits_section/edit_component.html.erb"
                       ))
    fields = File.read(presskits_path(
                         "app/views/recording_studio_presskits/credits_section/_line_fields.html.erb"
                       ))
    component = File.read(presskits_path(
                            "app/components/recording_studio_presskits/credits_section/edit_component.rb"
                          ))
    order = File.read(presskits_path("lib/recording_studio_presskits/quote_order.rb"))
    routes = File.read(presskits_path("config/routes.rb"))

    assert_includes editor, "FlatPack::CollectionEditor::Component"
    assert_includes editor, 'add_label: "Credit"'
    assert_includes editor, 'empty_text: "No credits yet"'
    assert_includes editor, 'text: "Save"'
    assert_includes editor, "style: :default"
    refute_includes editor, "style: :primary"
    assert_includes editor, "flat-pack--unsaved-changes"
    assert_includes editor, '"flat-pack--unsaved-changes-target": "submit"'
    assert_includes editor, 'id="presskits-credit-lines-save"'
    assert_operator editor.index("FlatPack::CollectionEditor::Component"), :<, editor.index('text: "Save"')
    assert_includes editor, "moving_recording_id"
    assert_includes editor, "target_position"
    assert_includes editor, 'child_index: "NEW_RECORD"'
    refute_includes editor, "Add credit"
    refute_includes component, "def section_actions"
    refute File.exist?(presskits_path(
                         "app/components/recording_studio_presskits/credits_section/actions_component.rb"
                       ))
    assert_includes fields, 'label: "Role on this kit"'
    assert_includes fields, "chrome: :cell"
    assert_includes fields, 'label: "Credit"'
    assert_includes fields, 'search_placeholder: "Search credits"'
    assert_includes fields, 'data: { create_field: "name", fill_from_query: "true" }'
    assert_includes fields, 'label: "Default role"'
    refute_includes fields, 'label: "Usual role"'
    assert_includes fields, 'create_field: "usual_role"'
    assert_includes fields, 'form: "collection-editor-unattached"'
    assert_includes order, "moving_recording_id"
    assert_includes order, "target_position"
    assert_includes routes, "get :search"
    assert_includes routes, "resource :credit_lines, only: :update"
    assert_includes editor, "recording-studio-presskits--credit-preview"
    assert_includes editor, "preview_actions"
    assert_includes editor, "data-credit-catalog"
    assert_includes component, "def preview_actions"
    assert_includes component, "collection-editor:selected->recording-studio-presskits--credit-preview#choose"
    assert_includes component, "input->recording-studio-presskits--credit-preview#role"
    assert_includes component, "click->recording-studio-presskits--credit-preview#drop"
    assert_includes component, "click->recording-studio-presskits--credit-preview#note"
    assert_includes component, "list:reordered->recording-studio-presskits--credit-preview#sync"
    assert_includes component, "def credit_catalog"
    show = File.read(presskits_path(
                       "app/components/recording_studio_presskits/credits_section/component.html.erb"
                     ))
    assert_includes show, "data-credit-lines"
    assert_includes show, "data-credit-line-id"
    assert_includes show, "data-credit-role"
    assert_includes show, "data-credit-name"
    refute_includes show, "if lines.any?"
    preview = File.read(presskits_path(
                          "app/javascript/recording_studio_presskits/controllers/credit_preview_controller.js"
                        ))
    assert_includes preview, "presskits-section-preview"
    assert_includes preview, "data-credit-line-id"
    assert_includes preview, "choose(event)"
    assert_includes preview, "role(event)"
    assert_includes preview, "drop(event)"
    assert_includes preview, "note(event)"
    assert_includes preview, "markFormChanged"
    assert_includes preview, "orderableUnsaved"
    show_component = File.read(presskits_path(
                                 "app/components/recording_studio_presskits/credits_section/component.rb"
                               ))
    assert_includes show_component, "def render?"
    assert_includes show_component, "lines.any?"
  end

  def test_video_routes_initializer_and_gemfile_pins
    root = File.expand_path("..", __dir__)
    routes = File.read(File.join(root, "config/routes.rb"))
    initializer = File.read(File.join(root, "test/dummy/config/initializers/recording_studio.rb"))
    gemfile = File.read(File.join(root, "Gemfile"))

    assert_includes routes, "resources :videos"
    refute_includes routes, "video_order"
    assert_includes initializer, '"RecordingStudioPresskits::VideoSection"'
    assert_includes initializer, '"RecordingStudioVideo::Video"'
    assert_includes gemfile, 'gem "recording_studio_video", "~> 0.1.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.4"'
  end

  def test_video_edit_calls_video_helpers_and_does_not_build_an_iframe
    root = File.expand_path("..", __dir__)
    component = File.read(File.join(root, "app/components/recording_studio_presskits/videos/edit_component.rb"))
    template = File.read(File.join(root, "app/components/recording_studio_presskits/videos/edit_component.html.erb"))

    assert_includes component, "recording_studio_video_fields"
    assert_includes component, "recording_studio_video_player"
    [component, template].each do |source|
      refute_includes source, "<iframe"
      refute_includes source, "FlatPack::UrlInput"
      refute_includes source, "FlatPack::TextInput"
      refute_includes source, "FlatPack::TextArea"
    end
  end

  def test_presskits_source_does_not_register_embed_providers
    root = File.expand_path("..", __dir__)
    Dir.glob(File.join(root, "{app,lib,config}/**/*.{rb,erb}")).each do |path|
      source = File.read(path)
      refute_includes source, "ExternalEmbed.register", path
      refute_includes source, "ExternalEmbed.resolve", path
      refute_includes source, "Playback", path
      refute_includes source, "::YouTube", path
    end
  end
end
