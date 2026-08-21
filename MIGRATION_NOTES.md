# Upgrade notes

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
3. PressKit already enables Orderable, Trashable, and Duplicatable. Do not enable Orderable on PressKit children.
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
