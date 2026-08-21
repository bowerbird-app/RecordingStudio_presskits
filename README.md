# Recording Studio Press Kits

A press kit is the folder you fill. Later addons drop in the sections — bio, downloads, logos. This gem is the container only.

Kits sit under your workspace. You can have many. This slice ships the authenticated editor: an index of kits and a kit page for adding, removing, and reordering sections. Staff get one Admin list of live kits. Publish is still later.

## Install

Add the gem next to Recording Studio 4.2, Accessible, Admin 2.0, and the three mixins PressKit opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.0"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.133"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_orderable", "~> 0.2"
gem "recording_studio_trashable", "~> 0.4"
gem "recording_studio_duplicatable", "~> 0.4"
gem "flat_pack", ">= 0.1.133"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_presskits:install
bin/rails generate recording_studio_presskits:migrations
bin/rails generate recording_studio_orderable:install
bin/rails generate recording_studio_orderable:migrations
bin/rails generate recording_studio_trashable:install
bin/rails generate recording_studio_trashable:migrations
bin/rails generate recording_studio_duplicatable:install
bin/rails generate recording_studio_admin:install
bin/rails db:migrate
```

The install generator mounts the user slice, writes `parent_root_type`, and enables `section :press_kits` when an `AdminRoot` model is already there. Duplicatable has no engine-owned schema.

Point the host root at the mounted slice, or redirect `/` there. Dummy redirects `/` to `/recording_studio_presskits`.

## Press kits

Register the type next to your host root. Dummy uses `Workspace`. Name that parent on install (`--parent-root-type`) or in the initializer. There is one declaration, not a second DSL.

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "RecordingStudioPresskits::PressKit"
  ]
  config.require_recordable_declarations = true
end

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
end
```

The kit declares itself as a nested type under that root, then opts into Orderable, Trashable, and Duplicatable with the current `.to` API only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path for these mixins.

```ruby
recording_studio_recordable label: "Press kit",
                            root: false,
                            allowed_parent_types: [RecordingStudioPresskits.parent_root_type]

include RecordingStudio::Capabilities::Orderable.to
include RecordingStudio::Capabilities::Trashable.to
include RecordingStudio::Capabilities::Duplicatable.to(
  suffix: " (Copy)",
  exclude_children: []
)
```

Orderable is enabled on the kit, not on its children. Omit `allows:` so every direct child type can sort — dummy `FakeBlock` now, later section addons later. Position is a column on the child recording. Reorder history is an event on the parent.

Duplicatable's README takes `include_children` as an array of types, not `true`. Leaving both include and exclude unset copies nothing. `exclude_children: []` copies every direct child without listing dummy types in this gem.

Core 4.2 stores type names as the class name. There is no public alias, so later section addons must use:

```ruby
allowed_parent_types: ["RecordingStudioPresskits::PressKit"]
```

Create kits and change them with public helpers. Do not insert Recording or Event rows by hand.

```ruby
root = RecordingStudio.root_recording_for(workspace)
kit_recording = root.record(RecordingStudioPresskits::PressKit) do |kit|
  kit.title = "Spring launch"
end

root.revise(kit_recording) do |kit|
  kit.title = "Spring launch, take two"
end

kit_recording.log_event!(action: "noted")
```

Core `record` defaults the parent to the workspace root. Nest a section under the kit by passing the kit as `parent_recording`:

```ruby
kit_recording.record(SomeSection, parent_recording: kit_recording) do |section|
  section.title = "Hero"
end
```

Reorder, trash, and duplicate through the mixin APIs. Do not write `recording_studio_orderable_position` by hand.

```ruby
kit_recording.recording_studio_orderable_children
kit_recording.recording_studio_orderable_reorder!(
  ordered_recording_ids: [quotes.id, hero.id],
  actor: current_user
)
kit_recording.recording_studio_orderable_move!(hero, to_index: 0, actor: current_user)

kit_recording.recording_studio_trashable_trash!(actor: current_user)
kit_recording.recording_studio_trashable_restore!(actor: current_user)

kit_recording.duplicate_in_place!(actor: current_user)
```

Prefer `RecordingStudio::Recording.recording_studio_trashable_active` over a host `default_scope`, unless the host already needs one for queries.

Section addons opt in solely by declaring PressKit as a parent. This gem does not keep a list of block types. The picker lists whatever the host has registered:

```ruby
RecordingStudioPresskits.picker_types
# => types whose allowed_parent_types include RecordingStudioPresskits::PressKit
```

The kit page walks children in order and renders each type's component. Register a host or addon component; the container does not style the blocks.

```ruby
RecordingStudioPresskits.register_section_component("FakeBlock", "FakeBlock::Component")
```

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index and kit pages are ViewComponents you can reuse or replace.

- Index: the current root's live kits. Same list as cards or a table, switched with `FlatPack::SegmentedButtons::Component`.
- Empty index: what happened, and a way to make a kit.
- Kit page: children in order, picker from `picker_types`, remove, reorder. Empty kit still shows the picker.

One primary action per page: **New press kit** on the index, **Create** on the new form, **Add a section** on the kit page via the picker.

## Admin

This gem registers one Admin section, `press_kits`, with one list widget of live kits. Enable it on your admin root. Do not invent published counts or a vanity total.

```ruby
class AdminRoot < ApplicationRecord
  include RecordingStudioAdmin::AllowsAdminSections

  recording_studio_recordable label: "Admin", root: true, shared: false
  RecordingStudio.enable_capability(:accessible, on: self)

  recording_studio_admin_sections do
    section :press_kits
  end
end
```

```ruby
mount RecordingStudioAccessible::Engine, at: "/admin/access"
recording_studio_admin_for :admin, at: "/admin", root_section: :press_kits
```

Staff reach it through Accessible grants on the admin root, not `user.admin?`. Missing auth or access fails closed.

## Dummy host

`test/dummy/` is a host that proves the gem. It is not the product.

| Field    | Value           |
|----------|-----------------|
| Email    | admin@admin.com |
| Password | Password        |

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `v4.2.0` |
| Accessible | `v0.6.1` |
| Admin | `2.0.0` |
| Root Switchable | `v0.5.0` |
| FlatPack | `v0.1.133` |
| Orderable | `0.2.0` |
| Trashable | `0.4.0` |
| Duplicatable | `0.4.0` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.2 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, kit show, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, and this gem so that layout is not an unstyled box.

Cards, table, kit show, and the Admin list: `docs/dummy-screenshots/`.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one kit titled **Spring launch** and two host-only fake sections (**Hero**, **Quotes**) so reorder is obvious. Dummy Workspace enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. Dummy `FakeBlock` enables Trashable so remove is testable without a real addon. The seeded admin user gets Accessible owner access on the workspace and the admin root.

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
