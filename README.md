# Recording Studio Press Kits

A press kit is the folder you fill. Later addons drop in the sections — bio, downloads, logos. This gem is the container only.

Kits sit under your workspace. You can have many. When the time comes, you publish the kit, not each block.

This slice does not ship an editor, a public page, or publish yet. Hosts register the type and write through Recording Studio.

## Install

Add the gem next to Recording Studio 4.2 and Accessible. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_presskits:install
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

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

The kit declares itself as a nested type under that root:

```ruby
recording_studio_recordable label: "Press kit",
                            root: false,
                            allowed_parent_types: ["Workspace"]
```

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

Section addons opt in solely by declaring PressKit as a parent. This gem does not keep a list of block types. The picker lists whatever the host has registered:

```ruby
RecordingStudioPresskits.picker_types
# => types whose allowed_parent_types include RecordingStudioPresskits::PressKit
```

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL.

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

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one kit and one host-only fake section so later add/remove work is not empty.

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
