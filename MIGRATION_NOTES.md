# Upgrade notes

## 0.7.0

The kit editor is a form plus an add dropdown. Default-layout chrome is page actions only.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Same gem pins as 0.6.0

### Host app

1. Creating a kit now lands on edit. Add, remove, and reorder return there too. Update any overridden redirects.
2. Replace the picker card with `RecordingStudioPresskits::PressKits::SectionDropdownComponent` (Flatpack `Button::Dropdown`). Types still come from `picker_types` / `allowed_parent_types`.
3. Keep test-only children off the dropdown with `config.excluded_picker_types`. Dummy excludes `FakeBlock`.
4. Put only page actions in `page_nav_right`. Access stays. Do not insert Sign in, Sign out, or Root Switchable into default layout. Core owns back and close.
5. Logged-out public show stays default layout with back and close only.
6. Re-seed dummy if you still have Hero / Quotes / Notes children. Seed is Spring launch published and Autumn recap unpublished.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.6.0

Publish the kit, not each block. A live kit has a public page. An owner can preview a kit that is not live yet.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.0`)
- Orderable `~> 0.2` (dummy GitHub tag `0.2.0`)
- Trashable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Duplicatable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Publishable `~> 0.2` (dummy GitHub tag `v0.2.0`)
- FlatPack `>= 0.1.133` (dummy GitHub tag `v0.1.133`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it

### Host app

1. Add `recording_studio_publishable`, `~> 0.2`.
2. Run `bin/rails generate recording_studio_publishable:install` and the Publishable migrations generator.
3. Register `"RecordingStudioPublishable::Publishable"` next to `"RecordingStudioPresskits::PressKit"`.
4. Mount Publishable at `/` so live kits use `/published/:uuid/:slug`. Point `.to` `public_layout` at `recording_studio/default_layout`. Do not use Publishable's empty TopNav. Do not invent a press-kit public shell.
5. PressKit already enables Publishable with `.to` only (`public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`, `public_layout: "recording_studio/default_layout"`). The public controller includes `UsesDefaultLayout`. Do not use `.with`. Do not enable Publishable on section children.
6. Publish and unpublish through `RecordingStudioPublishable::Services::Publishables::Update` (or Publishable's management screens). Prefer `publishable_public_path`, `currently_published?`, `current_publishable`, `published?`, and `indexable?`.
7. Public lists use `PressKit.indexable`. Do not invent a second published query.
8. Admin now has live vs not-live widgets. Remove any host list-only / vanity-total widgets for kits.
9. Publishable's child uses Attachable for social cards. Add that gem in the host if Publishable cannot boot without it. Do not enable Attachable on PressKit.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.5.0

Authenticated press kit screens and one Admin list of live kits. This gem is still the container only.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.0`)
- Orderable `~> 0.2` (dummy GitHub tag `0.2.0`)
- Trashable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Duplicatable `~> 0.4` (dummy GitHub tag `0.4.0`)
- FlatPack `>= 0.1.133` (dummy GitHub tag `v0.1.133`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it

### Host app

1. Add `recording_studio_admin`, `~> 2.0` and FlatPack `>= 0.1.133`.
2. Re-run `bin/rails generate recording_studio_presskits:install` (same generator, not a second identity).
3. Set `config.parent_root_type` to your host root class. Dummy stays `Workspace`.
4. Mount the user slice and point `/` at it, or redirect there.
5. Install Admin 2.0, mount it under an admin root, enable `section :press_kits`, and grant Accessible access on that root. Do not use `user.admin?`.
6. Register a component per child type with `register_section_component`. The container walks live children in order (`KitQuery.live_children`) and renders those components.
7. Keep writes on `record` / `revise` / `log_event!`. Query live kits with `recording_studio_trashable_active`.
8. Dummy puts Flatpack's built-in rounded theme on `<html data-theme="rounded">` via a host override of `recording_studio/default_layout`. Keep `UsesDefaultLayout`. Do not invent a custom theme.

Do not add Publishable, Attachable, or API in this slice.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.4.0

Press kits can be ordered, trashed, restored, and duplicated. This gem is still the container only.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Orderable `~> 0.2` (dummy GitHub tag `0.2.0`)
- Trashable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Duplicatable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it
- FlatPack dummy tag `v0.1.133`

### Host app

1. Add `recording_studio_orderable`, `~> 0.2`, `recording_studio_trashable`, `~> 0.4`, and `recording_studio_duplicatable`, `~> 0.4`.
2. Run each mixin's install generator. Run Orderable and Trashable migrations. Duplicatable has no engine-owned schema.
3. PressKit already enables Orderable, Trashable, and Duplicatable with `.to` only. Do not use `.with` or a second enablement path. Do not enable Orderable on PressKit children.
4. Reorder with `recording_studio_orderable_children` / `reorder!` / `move!`. Trash with `recording_studio_trashable_trash!` / `restore!` / `purge!`. Duplicate with `duplicate_in_place!` or `DuplicationService`.
5. Prefer `RecordingStudio::Recording.recording_studio_trashable_active` over a new host `default_scope`.
6. Accessible grants on the workspace root still cover kits. Mixin writes authorize through Accessible.
7. Duplicatable copies every direct child (`exclude_children: []`). The README does not accept `include_children: true`.

Do not add Publishable, Attachable, or API in this slice.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.3.0

This repo is now Recording Studio Press Kits, not the addon starting point.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it
- FlatPack dummy tag `v0.1.133`

### Host app

1. Change the gem name from the old addon starting point to `recording_studio_presskits`.
2. Add `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`.
3. Register `"RecordingStudioPresskits::PressKit"` with your workspace type.
4. Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`.
5. Create kits with `root.record(RecordingStudioPresskits::PressKit)` and change them with `revise`.
6. Later section addons must declare `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Core 4.2 has no public type-name alias.
7. Core `record` defaults the parent to the workspace root. Nest a section with `parent_recording: kit_recording`.

Do not add Publishable, Orderable, Trashable, Duplicatable, Attachable, or API in this slice.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```
