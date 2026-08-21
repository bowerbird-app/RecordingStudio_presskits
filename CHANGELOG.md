# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-08-21

Publish the kit, not each block. A live kit is readable without signing in. An owner can preview a kit that is not live yet. Admin shows live vs not-live work. Nothing is in production — this breaks in place.

### Added
- Publishable on `RecordingStudioPresskits::PressKit` via `.to` only (`public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`)
- Public show that walks children in order and renders each type's public component. The container does not style the blocks
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
- PressKit already includes Publishable via `.to` only. Do not use `.with`. Do not enable Publishable on FakeBlock or later section children
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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.0
