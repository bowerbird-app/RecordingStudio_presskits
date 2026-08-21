# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-08-21

First product release of Recording Studio Press Kits. A press kit is the container under a host root. Later addons supply the sections. Publish the kit, not each block.

### Added
- `RecordingStudioPresskits::PressKit` nested recordable under the host root (`Workspace` in dummy)
- Title on the kit snapshot table `recording_studio_press_kits`
- `RecordingStudioPresskits.picker_types` lists host types that allow PressKit as a parent
- Dummy host-only `FakeBlock` so add/remove is testable without a real section addon
- Dummy seed for one press kit and one fake section
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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.0
