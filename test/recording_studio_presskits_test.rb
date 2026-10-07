# frozen_string_literal: true

require "test_helper"

class RecordingStudioPresskitsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.18.0", ::RecordingStudioPresskits::VERSION
  end

  def test_engine_and_dummy_keep_header_text_title_and_images_heading_migrations
    root = File.expand_path("..", __dir__)
    [
      "db/migrate/20261005120000_add_description_to_recording_studio_press_kits.rb",
      "db/migrate/20261006120000_add_title_to_recording_studio_texts.rb",
      "db/migrate/20261006140000_replace_images_caption_with_title_and_subtitle.rb",
      "db/migrate/20261006160000_introduce_recording_studio_kit_sections.rb",
      "test/dummy/db/migrate/20261005120000_add_description_to_recording_studio_press_kits.rb",
      "test/dummy/db/migrate/20261006120000_add_title_to_recording_studio_texts.rb",
      "test/dummy/db/migrate/20261006140000_replace_images_caption_with_title_and_subtitle.rb",
      "test/dummy/db/migrate/20261006160000_introduce_recording_studio_kit_sections.rb"
    ].each do |path|
      assert File.exist?(File.join(root, path)), path
    end
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPresskits::Engine
  end

  def test_gemspec_pins_recording_studio_and_accessible
    gemspec = File.read(File.expand_path("../recording_studio_presskits.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.11"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_admin", "~> 2.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_orderable", "~> 0.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_duplicatable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "flat_pack", ">= 0.1.198"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_publishable", "~> 0.4"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_attachable", "~> 0.7"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_api"'
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.2.2"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.11.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "v2.0.4"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.3"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.198"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.5"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.4.4"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.3"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.4.2"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.7.1"'
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
    assert_includes source, "operations: %i[show]"
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
    assert_includes default_layout, "anchor_tooltip:"
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
    assert_includes readme, "v4.2.2"
    assert_includes readme, "v0.11.1"
    assert_includes readme, "tag: \"v2.0.4\""
    assert_includes readme, "tag: \"v0.2.5\""
    assert_includes readme, "tag: \"v0.4.4\""
    assert_includes readme, "tag: \"v0.4.2\""
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
    assert_includes index, "FlatPack::Card::Component"
    assert_includes index, "card.media"
    assert_includes index, 'name: "photo"'
    assert_includes index, "presskits_cover_url_for"
    assert_includes index, "FlatPack::Table::Component"
    assert_includes index, "FlatPack::Grid::Component"
    assert_includes index, "FlatPack::EmptyState::Component"
    header = File.read(File.expand_path("press_kits/header_editor_component.html.erb", components))
    row = File.read(File.expand_path("press_kits/header_row_component.html.erb", components))

    assert_includes show, "SectionDropdownComponent"
    assert_includes show, "render_publishable_quick_actions"
    assert_includes show, "HeaderRowComponent"
    assert_includes show, 'id="presskits-kit-header"'
    assert_operator show.index('id="presskits-kit-header"'), :<, show.index('id="presskits-section-list"')
    refute_includes show, 'name: "press_kit[title]"'
    refute_includes show, 'name: "press_kit[description]"'
    refute_includes show, 'text: "Save"'
    assert_includes row, 'id: "presskits-header-row"'
    assert_includes row, 'icon: "bars-3-bottom-left"'
    assert_includes row, 'link_to "Header"'
    refute_includes row, "arrows-up-down"
    refute_includes row, "trash"
    assert_includes header, 'name: "press_kit[title]"'
    assert_includes header, 'name: "press_kit[description]"'
    assert_includes header, "max_characters: RecordingStudioPresskits::PressKit::SHORT_DESCRIPTION_LIMIT"
    assert_includes header, 'text: "Update", style: :primary'
    assert_includes header, 'text: "Cancel", style: :default'
    assert_includes header, "cols: 2"
    assert_includes header, 'id: "presskits-header-edit-preview"'
    assert_operator header.index('name: "press_kit[title]"'), :<, header.index('id: "presskits-header-edit-preview"')
    refute_includes show, "EditButtonComponent"
    refute_includes show, "Go live"
    refute_includes show, "SectionPickerComponent"
    refute_includes show, "FlatPack::Picker::Component"
    refute_includes index, "Dummy host"
  end

  def test_section_dropdown_passes_a_menu_icon
    dropdown = File.read(presskits_path(
                           "app/components/recording_studio_presskits/press_kits/section_dropdown_component.html.erb"
                         ))
    editor = File.read(presskits_path("app/components/recording_studio_presskits/press_kits/kit_editor_component.rb"))
    text = File.read(presskits_path("app/models/recording_studio_presskits/text.rb"))
    images = File.read(presskits_path("app/models/recording_studio_presskits/images.rb"))
    quotes = File.read(presskits_path("app/models/recording_studio_presskits/quote_section.rb"))

    assert_includes dropdown, "icon: item[:icon]"
    assert_includes editor, "section_menu_icon_for"
    assert_includes text, '"document-text"'
    assert_includes images, '"photo"'
    assert_includes quotes, '"chat-bubble-bottom-center-text"'
  end

  def presskits_path(relative)
    File.expand_path("../#{relative}", __dir__)
  end

  def test_images_editor_names_title_and_subtitle
    editor = File.read(presskits_path("app/components/recording_studio_presskits/images/edit_component.html.erb"))
    component = File.read(presskits_path("app/components/recording_studio_presskits/images/edit_component.rb"))
    show = File.read(presskits_path("app/components/recording_studio_presskits/images/component.html.erb"))

    frame_path = "press_kits/section_frame_component.html.erb"
    editor_path = "press_kits/section_editor_component.html.erb"
    frame = File.read(presskits_path("app/components/recording_studio_presskits/#{frame_path}"))
    section_editor = File.read(presskits_path("app/components/recording_studio_presskits/#{editor_path}"))

    refute_includes editor, 'name: "images[title]"'
    refute_includes editor, 'name: "images[subtitle]"'
    refute_includes editor, "images[caption]"
    assert_includes section_editor, 'name: "kit_section[title]"'
    assert_includes section_editor, 'name: "kit_section[subtitle]"'
    assert_operator section_editor.index('name: "kit_section[title]"'), :<,
                    section_editor.index('name: "kit_section[subtitle]"')
    assert_includes component, "def self.permitted_attributes\n        []"
    refute_includes show, "FlatPack::SectionTitle::Component"
    assert_includes frame, "FlatPack::SectionTitle::Component"
    assert_includes frame, "anchor_link: true"
    assert_includes frame, "subtitle: subtitle"
    assert_includes section_editor, 'id: "presskits-section-grid"'
    assert_includes section_editor, "cols: 2"
    assert_includes section_editor, 'id="presskits-section-fields"'
    assert_includes section_editor, 'id="presskits-section-preview"'
    refute_includes section_editor, "preview?"
    refute_includes section_editor, "if form?"
    refute_includes component, "def self.preview?"
    refute_includes component, "preview_card_title"
    assert_includes component, "def self.below?"
    assert_includes editor, 'text: "Upload"'
    assert_operator editor.index("flex flex-wrap items-center gap-3"), :<, editor.index('text: "Upload"')
    assert_includes editor, "upload_form_data(helpers)"
    refute_includes section_editor, "upload_form_data"
  end

  def test_section_editor_puts_fields_before_update_and_custom_ui_below
    editor_path = "press_kits/section_editor_component.html.erb"
    section_editor = File.read(presskits_path("app/components/recording_studio_presskits/#{editor_path}"))
    component_path = "press_kits/section_editor_component.rb"
    component = File.read(presskits_path("app/components/recording_studio_presskits/#{component_path}"))
    quotes = File.read(presskits_path("app/components/recording_studio_presskits/quote_section/edit_component.rb"))
    text = File.read(presskits_path("app/components/recording_studio_presskits/text/edit_component.rb"))

    assert_operator section_editor.index('name: "kit_section[title]"'), :<,
                    section_editor.index('name: "kit_section[subtitle]"')
    assert_operator section_editor.index('name: "kit_section[subtitle]"'), :<,
                    section_editor.index("fields_in_form?")
    assert_operator section_editor.index("fields_in_form?"), :<, section_editor.index('text: "Update"')
    assert_operator section_editor.index('text: "Update"'), :<, section_editor.index("section_actions")
    assert_operator section_editor.index("section_actions"), :<, section_editor.index("below_editor?")
    assert_includes component, "def fields_in_form?"
    assert_includes component, "def below_editor?"
    refute_includes component, "def form?"
    assert_includes quotes, "def below?"
    refute_includes quotes, "def form?"
    refute_includes quotes, "def self.form?"
    refute_includes text, "def self.below?"
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
    assert_includes section_editor, 'label: "Title"'
    assert_includes section_editor, 'name: "kit_section[title]"'
    assert_includes section_editor, "cols: 2"
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
end
