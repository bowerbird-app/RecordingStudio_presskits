# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.15.0] - 2026-10-06

Kit header.

### Added
- A press kit has an optional short description, 280 characters at most. A blank one is stored as nothing. The kit editor lists Header with the sections. That row opens a screen for the title and short description. The screen is a two-column grid: the fields, then a preview. The row cannot be removed or reordered. The kit preview, the public page, and owner preview show the description under the title when it is present.

### Changed
- Renaming a kit moves from `PATCH press_kits/:id` to `PATCH press_kits/:press_kit_id/header`, which also saves the short description.
- Version `0.15.0`
- FlatPack is `>= 0.1.198` (dummy tag `v0.1.198`).
- Point host and dummy Gemfiles at Recording Studio `v4.2.2`
- Point sibling Recording Studio gems at current tags: Accessible `v0.11.1`, Admin `v2.0.4`, Attachable `v0.7.1`, Duplicatable `v0.4.3`, Orderable `v0.2.5`, Publishable `v0.4.2`, Trashable `v0.4.4`, and dummy Root Switchable `v0.5.3`.
- Gemspec constraints: Accessible `~> 0.11`, Publishable `~> 0.4`
- Dummy Accessible roles are strings (`view` / `edit` / `admin`). Grants still go through `bootstrap_owner_access!` / `grant_access`. Accessible 0.8–0.11 migrations are in `test/dummy`.
- Gem tests keep a tiny `Object#stub` helper because Minitest 6 dropped `minitest/mock`.

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_press_kits` gains a nullable `description`. Existing kits keep their title and start with no description. If the dummy database was migrated on 0.14.0, this also restores `20261006120000` (text section title) so migrate and rollback can see that file.
- Bump FlatPack to at least `0.1.198`. Link `stylesheet_link_tag "flat_pack/application"` beside `flat_pack/variables` on host layouts. That sheet paints primary buttons. The public blank layout already links it.
- Bump `recording_studio_accessible` to `~> 0.11` and run `bin/rails generate recording_studio_accessible:migrations`. Access `role` becomes a string.
- Bump `recording_studio_publishable` to `~> 0.4`.
- Pin Admin, Attachable, Duplicatable, Orderable, Trashable, and Root Switchable to the tags above.

## [0.14.0] - 2026-10-06

Text section title.

### Added
- A text section has an optional title. A blank one is stored as nothing. The text editor shows Title and Body, each with its name. The kit preview and the public page show that title with FlatPack's section title and its anchor when it is set. The kit row stays Text.

### Changed
- + Section menu items show a Heroicon beside Text, Images, and Quotes.
- Version `0.14.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_texts` gains a nullable `title`. Existing text sections start with no title. The title is no longer taken from the first line of the body.

## [0.13.0] - 2026-10-02

Images editor.

### Changed
- The Images editor edits each photo with Attachable's `attachment_collection_editor`: caption, credit, and alt text, then Save. Trash on a photo returns to the section. The section caption and the Upload button stay.
- Attachable is `~> 0.7` (dummy tag `v0.7.0`). FlatPack is `>= 0.1.135` (dummy tag `v0.1.135`).
- Version `0.13.0`

### Upgrade notes
- Bump `recording_studio_attachable` to `~> 0.7` and FlatPack to at least `0.1.135`.
- Run `bin/rails generate recording_studio_attachable:migrations` and `bin/rails db:migrate`. Attachment rows gain `root_recording_id`, `caption`, `credit`, and `alt_text`.

## [0.12.0] - 2026-10-02

Quote display.

### Changed
- A quote row shows the quote, truncated to the column, with the name on the line below.
- The quotes action is + Quote: a Heroicons plus icon and the label Quote.
- Column two, the kit preview, and the public page render each quote with FlatPack's quote component at large size. The citation is the name, role, and organisation.
- Version `0.12.0`

### Upgrade notes
- No host or schema changes

## [0.11.0] - 2026-10-02

Quotes section.

### Added
- `RecordingStudioPresskits::QuoteSection` is a press kit section. Each quote is a child recording with body, name, and optional role and organisation. The section editor is an orderable list in column one, and column two previews the saved quotes. Add quote and Cancel sit above that grid. Each quote has its own edit screen. Orderable is on the quote section. Attachable is on the quote for one image. A blank body stays off the preview and the public page.

### Changed
- Version `0.11.0`

### Upgrade notes
- Add `"RecordingStudioPresskits::QuoteSection"` and `"RecordingStudioPresskits::Quote"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`

## [0.10.0] - 2026-10-01

Images section. Attachable is 0.4.

### Added
- `RecordingStudioPresskits::Images` is a press kit section. The field is an optional `caption`. Photos are Attachable image attachments on that section, so one section holds many images. Attachable stays off PressKit. The editor uploads from an Upload button after Cancel.

### Changed
- Version `0.10.0`
- The Images editor no longer shows a drag-and-drop upload area.

### Upgrade notes
- Add `"RecordingStudioPresskits::Images"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`
- Depend on `recording_studio_attachable`, `~> 0.4`, mount that engine, and wire Active Storage direct uploads

## [0.9.0] - 2026-10-01

Two-column kit editor and the Text section. Accessible is 0.10.

### Added
- `RecordingStudioPresskits::Text` is a press kit section. The field is `body`. Hosts add the class to `recordable_types` and run the migrations generator.

### Changed
- Version `0.9.0`
- The kit URL requires edit access and redirects to a two-column editor. Hosts register section editors with `register_section_editor`. Text registers its own editor.
- On the kit editor, the page heading is the kit name. + Section and the publish control share one row above the two-column grid. + Section is first and uses the primary button. The label is Section with a Heroicons plus icon. The title form and Save are gone from this page.
- Each section's remove control is a trash icon. Destroy calls `recording_studio_trashable_trash!`.
- Kit sections share one list inside one card. The link is the section type. The preview column is one card.
- Section order uses FlatPack list `orderable: true` and `divider: true`. The `arrows-up-down` icon stays in the list icon slot. This FlatPack pin does not persist the drop, so `list:reordered` calls `recording_studio_orderable_move!`. Move up and Move down are gone. Hosts pin `controllers/recording_studio_presskits` from the engine JavaScript.
- The Text field is FlatPack's content WYSIWYG. The kit editor and the public page render the saved HTML. A new Text section opens with a heading, a paragraph, and a list. The section editor has no Remove button.
- **+ Access** is on the kit editor only. The index, the new form, the section editor, and owner preview leave the page-nav right slot empty.
- Accessible is `~> 0.10` (dummy tag `v0.10.0`). + Access is a FlatPack link (`href:`) to manage access.
- A section editor shows the type as a page heading. Update and Cancel sit above the grid. Cancel uses the default button and returns to the kit. The default layout is two columns, with the preview in a card lined up with the field. The text field has no label of its own. Text hides that preview and uses one full-width column. An editor opts out by defining `preview?` and returning false.

### Upgrade notes
- Add `"RecordingStudioPresskits::Text"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`
- Bump `recording_studio_accessible` to `~> 0.10` and run its migrations generator
- Pin `controllers/recording_studio_presskits` so a section drop can save

## [0.8.0] - 2026-10-01

Index and public page. Publishable is 0.3.

### Added
- Kit cards show a 16/9 cover. A recordable can supply `cover_image_url`. A missing or unsafe URL uses the muted card color and a photo icon

### Changed
- Version `0.8.0`
- Index primary action is **Presskit** with a Heroicons `plus` icon. It stays first and left, ahead of the cards / table toggle
- Index page title is **My presskits**
- Publishable is `~> 0.3` (dummy tag `v0.3.1`). Kit show and kit edit use `render_publishable_quick_actions` for the publish control
- Public kit view uses `recording_studio_presskits/blank`. View and the publish-button Preview render the kit with no page nav. Owner preview stays on `recording_studio/default_layout`

### Upgrade notes
- Bump `recording_studio_publishable` to `~> 0.3`
- Public kits use `recording_studio_presskits/blank`. Do not point `public_layout` back at `recording_studio/default_layout`

## [0.7.1] - 2026-09-03

Cloud Agent Builds fetch Cursor skills at Build. Product is unchanged.

### Added
- Cloud Agent boot files: `.cursor/environment.json`, `.cursor/install.sh`, `.cursor/fetch-skills.sh`, and `.cursor/start.sh`
- [Cursor skills in Cloud Agents](docs/cursor-skills.md)
- Tests for the install hook warm skip, skippable provision, and dummy boot files

### Changed
- Version `0.7.1`
- `.cursor/install.sh` skips apt, ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are already usable. A skippable provision failure does not fail the Build. Fetch-skills always runs last

### Upgrade notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft off so Build loads the pack

## [0.7.0] - 2026-08-22

The kit editor is a form and one action row. Chrome on default-layout screens is page actions only. Dummy seed stays two kits and no fake sections.

### Added
- Kit edit screen with the kit title form and a Flatpack **Add a section** dropdown under the title
- The same row holds Preview and Publishable's **Draft / Published** action (`EditButtonComponent`)
- `excluded_picker_types` so hosts can keep test-only children off the dropdown
- Dummy excludes `FakeBlock` from the dropdown. FakeBlock stays for tests only

### Changed
- Version `0.7.0`
- Creating a kit lands on edit
- Add, remove, and reorder return to edit
- Default-layout page-nav right slot is Access only (`recording_studio_accessible_avatars`). Sign out and Root Switchable stay out of that slot, dummy extra nav, and gem views that use default layout
- Logged-out public show stays default layout with back and close only. No Sign in
- Owner preview can show Access. No Sign out or Root Switchable
- Dummy seed: **Spring launch** published, **Autumn recap** unpublished, no seeded fake sections
- Kit edit Save stays normal size (`items-start`). Empty kits skip the empty-state tray. An add dropdown with no types is a disabled button, not an empty menu hole
- Index toolbar is left-justified: **New press kit** first, then icon-only `FlatPack::ButtonGroup::Component` for cards vs table (`squares-2x2` / `table-cells`). No Cards / Table labels. No Press kits helper. This Flatpack pin's SegmentedButtons is text-only.

### Removed
- The "Add a section" picker card and radio list
- Dummy `presskits_extra_nav` Sign out control

### Upgrade notes
- Point create / add / remove / reorder at `edit_press_kit_path` if you overrode those redirects
- Replace any host copy of the picker card with `SectionDropdownComponent` (Flatpack Button Dropdown)
- Do not put Sign in, Sign out, or Root Switchable into `page_nav_right` or `recording_studio/default_layout`. Core owns back and close. Access stays in the slot
- Keep **New press kit** first and left on the index. Cards vs table is icon-only `FlatPack::ButtonGroup::Component`. Do not invent a Press kits toggle
- If a dummy or test type should stay off the add dropdown, set `config.excluded_picker_types`
- Re-seed dummy to drop leftover Hero / Quotes / Notes children

## [0.6.0] - 2026-08-21

Publish the kit, not each block. A live kit is readable without signing in. An owner can preview a kit that is not live yet. Admin shows live vs not-live work. Nothing is in production — this breaks in place.

### Added
- Publishable on `RecordingStudioPresskits::PressKit` via `.to` only (`public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`, `public_layout: "recording_studio/default_layout"`)
- Public show that walks children in order and renders each type's public component. The container does not style the blocks. Logged-out public show uses Recording Studio's default layout (`UsesDefaultLayout`), not Publishable's empty TopNav
- Owner preview of a kit that is not live, on Recording Studio's default layout
- Admin widgets for live kits (`PressKit.indexable`) and kits that are not live yet. Still no vanity total
- Dummy seed publishes **Spring launch** and leaves **Autumn recap** unpublished
- Dummy mounts Publishable at `/` and registers `RecordingStudioPublishable::Publishable`

### Changed
- Version `0.6.0`
- Gemspec adds `recording_studio_publishable`, `~> 0.2`
- Dummy GitHub tag adds Publishable `v0.2.0`
- Picker uses declared parent types so Publishable's capability child stays off the list
- `KitQuery.live_children` skips the Publishable child

### Upgrade notes
- Add `recording_studio_publishable`, `~> 0.2` (dummy GitHub tag `v0.2.0`)
- Run `bin/rails generate recording_studio_publishable:install` and `bin/rails generate recording_studio_publishable:migrations`
- Register `"RecordingStudioPublishable::Publishable"` in `RecordingStudio.configure`
- Mount `RecordingStudioPublishable::Engine` at `/` (or keep the path Publishable's README uses)
- PressKit already includes Publishable via `.to` only, with `public_layout: "recording_studio/default_layout"`. Do not use `.with`. Do not enable Publishable on FakeBlock or later section children. Do not use Publishable's public layout as the public shell
- Use `PressKit.indexable` / `indexable?` for public lists. Publish and unpublish through Publishable's services
- Replace any host list-only Admin widget with the live / not-live widgets this gem now registers
- Publishable's child recordable uses Attachable for social cards. Dummy pins Attachable `0.4.0` so that child can boot. Do not enable Attachable on PressKit

## [0.5.0] - 2026-08-21

Authenticated press kit screens and a staff list of live kits. This gem is still the container only — later addons are the sections. No public page and no publish.

### Added
- Mountable user slice: index of the current root's kits, kit editor, picker add, remove, and reorder
- Cards and table views of the same kit list, switched with `FlatPack::SegmentedButtons::Component`
- Reusable ViewComponents for index, kit show, child rows, and the section picker
- Empty index and empty kit states
- Admin section `press_kits` with one list widget of live kits (`recording_studio_admin`, `~> 2.0`)
- Install generator writes `parent_root_type` and enables `section :press_kits` when an AdminRoot model exists
- Dummy Admin root, Admin mount, and Accessible bootstrap so the seeded admin user can open the list
- Dummy `FakeBlock::Component` so the kit page can render host children without styling them

### Changed
- Version `0.5.0`
- Gemspec adds `recording_studio_admin`, `~> 2.0` and `flat_pack`, `>= 0.1.133`
- Dummy GitHub tags add Recording Studio Admin `2.0.0`
- PressKit `allowed_parent_types` uses `RecordingStudioPresskits.parent_root_type` (default `"Workspace"`)
- Dummy `/` redirects to the mounted press kit index
- Dummy app name is "Press kits"
- Dummy overrides Recording Studio's default layout so `<html data-theme="rounded">` wraps index, kit show, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables`. Authenticated screens still use `UsesDefaultLayout`.
- Dummy PageNav maps core's `page_nav_anchor_url` slot to Flatpack 0.1.133 `anchor_href` and `anchor_tooltip` so the close X renders next to back on index, kit show, and new.

### Removed
- Dummy "Dummy host" landing page and workspace outline tree

### Upgrade notes
- Add `recording_studio_admin`, `~> 2.0` and FlatPack `>= 0.1.133`
- Run `bin/rails generate recording_studio_presskits:install` again (or mount the engine and copy the new initializer keys)
- Set `config.parent_root_type` to your host root class. Dummy stays `Workspace`
- Mount the user slice and point `/` at it, or redirect there
- Install Admin 2.0, create an admin root, enable `section :press_kits`, and grant Accessible access on that root
- Register a component per child type with `register_section_component`. Dummy registers `FakeBlock::Component`
- Do not enable Publishable, Attachable, or API in this slice

## [0.4.0] - 2026-08-21

Press kits can be ordered, trashed, restored, and duplicated. This gem is still the container only — no editor, no public page, no publish.

### Added
- `recording_studio_orderable`, `~> 0.2`, `recording_studio_trashable`, `~> 0.4`, and `recording_studio_duplicatable`, `~> 0.4`
- Orderable on `RecordingStudioPresskits::PressKit` with no `allows:` so every direct child type can sort
- Trashable on `RecordingStudioPresskits::PressKit`
- Duplicatable on `RecordingStudioPresskits::PressKit` with suffix `" (Copy)"` and `exclude_children: []` so FakeBlock and later section children copy with the kit
- Dummy `FakeBlock` enables Trashable so remove is testable without a real addon
- Dummy `Workspace` enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests
- Dummy seed for a second fake section (`Quotes`) so reorder is obvious
- Dummy mounts and migrations for Orderable and Trashable (Duplicatable has no engine-owned schema)

### Changed
- Dummy GitHub tags add Orderable `0.2.0`, Trashable `0.4.0`, and Duplicatable `0.4.0`
- Dummy home lists active recordings in Orderable position order

### Upgrade notes
- Add `recording_studio_orderable`, `recording_studio_trashable`, and `recording_studio_duplicatable` next to this gem
- Run each mixin's install generator and Orderable/Trashable migrations
- PressKit already includes the three mixins via `.to` only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path. Do not enable Orderable on PressKit children. Do not enable Duplicatable on FakeBlock — child copy is a parent filter, not a child opt-in.
- Duplicatable's README takes `include_children` as an array of types, not `true`. This gem uses `exclude_children: []` so every direct child type is copied.
- Reorder, trash, restore, purge, and duplicate through the mixin APIs. Prefer `recording_studio_trashable_active` over a new host `default_scope`.
- Accessible grants on the workspace root still cover kits. Mixin writes authorize through Accessible.
- Do not enable Publishable, Attachable, or API in this slice

## [0.3.0] - 2026-08-21

First product release of Recording Studio Press Kits. A press kit is the container under a host root. Later addons supply the sections. Publish the kit, not each block.

### Added
- `RecordingStudioPresskits::PressKit` nested recordable under the host root (`Workspace` in dummy)
- Title on the kit snapshot table `recording_studio_press_kits`
- `RecordingStudioPresskits.picker_types` lists host types that allow PressKit as a parent
- Dummy host-only `FakeBlock` so add/remove is testable without a real section addon
- Dummy seed for one press kit and one fake section
- Dummy authenticated home shows that seeded outline (host sandbox, not a product editor)
- Dummy Tailwind `@source` paths that actually find FlatPack and Recording Studio gems, so default layout CSS loads
- Dummy `rake tailwind:bundle_sources` writes those gem paths before each Tailwind build
- Gemspec dependencies `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`

### Changed
- Renamed the engine from the addon template to `recording_studio_presskits`
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.1`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`

### Removed
- Leftover template identity in the public README and gemspec
- Dummy starter docs pages
- Template example capability mixin
- Engine sample home controller

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.0` and Accessible `v0.6.1`
- Declare `spec.add_dependency "recording_studio", "~> 4.2"` and `spec.add_dependency "recording_studio_accessible", "~> 0.6"`
- Register `"RecordingStudioPresskits::PressKit"` in `RecordingStudio.configure`
- Later section addons must use `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Core 4.2 has no public type-name alias.
- Core `record` defaults the parent to the workspace root. Nest a section with `parent_recording: kit_recording`.
- Install engine migrations and keep writes on `record` / `revise` / `log_event!`
- Do not enable Publishable, Orderable, Trashable, Duplicatable, Attachable, or API in this slice

## [0.2.0] - 2026-08-21

Addon starting point on Recording Studio 4.x, before this repo became Press Kits.

### Added
- Gemspec dependency `recording_studio`, `~> 4.1`
- Dummy host wiring for Accessible (`enable_capability(:accessible, on: Workspace)`)
- `bin/rename_gem` leftover-identity rewrite/verification for README, homepage, and changelog URLs

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated layout is Recording Studio's default layout plus FlatPack CSS/JS; Devise keeps its own sign-in layout
- Dummy app security pins: Rails `8.1.3.1`, `json` `2.21.2`, `mail` `2.9.1`, Brakeman `8.0.6`
- Require `RecordingStudio::Hooks` and `RecordingStudio::Services::BaseService` from core instead of shipping copies

### Removed
- Copied Hooks and BaseService files
- Product-shipped example service
- Custom `flat_pack_sidebar` authenticated shell

### Upgrade notes
- Point dummy or host Gemfiles at Recording Studio `v4.2.0` (not `recording_studio/v3.0.0`)
- Add `spec.add_dependency "recording_studio", "~> 4.1"` to addon gemspecs
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Delete any copied Hooks or BaseService files and require the core classes
- Keep recordable declarations; they are required
- If Accessible is bundled, call `RecordingStudio.enable_capability(:accessible, on: Workspace)` (or your root type)

## [0.1.2] - 2026-07-21

### Changed
- Bumped the dummy app FlatPack dependency from `v0.1.33` to `v0.1.129`

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `v0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.15.0...HEAD
[0.15.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.13.0
[0.12.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.12.0
[0.11.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.11.0
[0.10.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.10.0
[0.9.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.9.0
[0.8.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.8.0
[0.7.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.7.1
[0.7.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.7.0
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.0
