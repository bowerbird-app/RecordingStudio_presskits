# Recording Studio Press Kits

A press kit is the folder you fill. Later addons drop in the sections — bio, downloads, logos. This gem is the container only.

Kits sit under your workspace. You can have many. When the time comes, you publish the kit, not each block.

This slice does not ship an editor, a public page, or publish yet. Hosts register the type and write through Recording Studio.

## Install

Add the gem next to Recording Studio 4.2, Accessible, and the three mixins PressKit opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
gem "recording_studio_orderable", "~> 0.2"
gem "recording_studio_trashable", "~> 0.4"
gem "recording_studio_duplicatable", "~> 0.4"
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
bin/rails db:migrate
```

Duplicatable has no engine-owned schema. Run its install generator so the host mounts the engine and gets the initializer.

## Press kits

Register the type next to your host root. Dummy uses `Workspace`.

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "RecordingStudioPresskits::PressKit"
  ]
  config.require_recordable_declarations = true
end
```

The kit declares itself as a nested type under that root, then opts into Orderable, Trashable, and Duplicatable:

```ruby
recording_studio_recordable label: "Press kit",
                            root: false,
                            allowed_parent_types: ["Workspace"]

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
# or RecordingStudioDuplicatable::Services::DuplicationService.call(...)
```

Prefer `RecordingStudio::Recording.recording_studio_trashable_active` over a host `default_scope`, unless the host already needs one for queries.

Section addons opt in solely by declaring PressKit as a parent. This gem does not keep a list of block types. The picker lists whatever the host has registered:

```ruby
RecordingStudioPresskits.picker_types
# => types whose allowed_parent_types include RecordingStudioPresskits::PressKit
```

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible.

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
| Root Switchable | `v0.5.0` |
| FlatPack | `v0.1.133` |
| Orderable | `0.2.0` |
| Trashable | `0.4.0` |
| Duplicatable | `0.4.0` |

Authenticated dummy screens use Recording Studio's default layout. Dummy Tailwind scans FlatPack and Recording Studio gem paths so that layout is not an unstyled box.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one kit and two host-only fake sections so reorder is obvious. After sign-in, dummy home shows that outline under Studio Workspace. It is a host sandbox, not the product editor. Dummy Workspace also enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. Dummy `FakeBlock` enables Trashable so remove is testable without a real addon.

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
