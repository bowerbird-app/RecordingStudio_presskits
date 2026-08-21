# Upgrade notes

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

Do not add Publishable, Orderable, Trashable, Duplicatable, Attachable, or API in this slice.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```
