# Recording Studio Press Kits

A press kit is the folder you fill. Later addons drop in the sections — bio, downloads, logos. This gem is the container only.

Kits sit under your workspace. You can have many. You publish the kit, not each block. This slice ships the authenticated editor, a public page for a live kit, an owner preview of a kit that is not live yet, and Admin widgets for live vs not-live work.

## Install

Add the gem next to Recording Studio 4.2, Accessible, Admin 2.0, Publishable 0.3, and the three mixins PressKit already opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.0"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.1"
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
gem "recording_studio_publishable", "~> 0.3"
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
bin/rails generate recording_studio_publishable:install
bin/rails generate recording_studio_publishable:migrations
bin/rails generate recording_studio_admin:install
bin/rails db:migrate
```

The install generator mounts the user slice, writes `parent_root_type`, and enables `section :press_kits` when an `AdminRoot` model is already there. Duplicatable has no engine-owned schema. Publishable's install mounts that engine at `/` so live kits use `/published/:uuid/:slug`.

Point the host root at the mounted slice, or redirect `/` there. Dummy redirects `/` to `/recording_studio_presskits`.

## Press kits

Register the type next to your host root. Dummy uses `Workspace`. Name that parent on install (`--parent-root-type`) or in the initializer. There is one declaration, not a second DSL. Register Publishable's child type too.

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "RecordingStudioPresskits::PressKit",
    "RecordingStudioPublishable::Publishable"
  ]
  config.require_recordable_declarations = true
end

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
end
```

The kit declares itself as a nested type under that root, then opts into Orderable, Trashable, Duplicatable, and Publishable with the current `.to` API only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path for these mixins. Do not enable Publishable on section children.

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
include RecordingStudio::Capabilities::Publishable.to(
  public_controller: "recording_studio_presskits/public_press_kits",
  public_action: :show,
  public_layout: "recording_studio_presskits/blank"
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

Publish and unpublish through Publishable's own services. Prefer `publishable_public_path`, `currently_published?`, `current_publishable`, `published?`, and `indexable?`. Public lists use `PressKit.indexable`. Do not invent a second published query.

```ruby
RecordingStudioPublishable::Services::Publishables::Update.call(
  parent_recording: kit_recording,
  actor: current_user,
  attributes: { slug: "spring-launch", status: "published" }
)

kit_recording.currently_published?
kit_recording.publishable_public_path
RecordingStudioPresskits::PressKit.indexable
```

Prefer `RecordingStudio::Recording.recording_studio_trashable_active` over a host `default_scope`, unless the host already needs one for queries.

Section addons opt in solely by declaring PressKit as a parent. This gem does not keep a list of block types. The add dropdown lists whatever the host has **declared** — capability children such as Publishable stay off that list. Test-only placeholders stay off it too:

```ruby
RecordingStudioPresskits.configure do |config|
  config.excluded_picker_types = ["FakeBlock"]
end

RecordingStudioPresskits.picker_types
# => types whose declared allowed_parent_types include RecordingStudioPresskits::PressKit
#    minus excluded_picker_types
```

If nothing real is registered, + Section is a disabled button. No empty menu box.

`RecordingStudioPresskits::Text` is the section this gem ships. Add it to the host `recordable_types`, then run `rails generate recording_studio_presskits:migrations` and migrate. The body is plain text. The row label is the first line. Trashable is on. Orderable stays on the kit. Publishable stays off the section.

The kit editor's preview column and the public page walk children in order and render each type's component. Text is registered. A later addon still registers its own component.

```ruby
RecordingStudioPresskits.register_section_component("SomeSection", "SomeSection::Component")

RecordingStudioPresskits.register_section_editor("SomeSection", "SomeSection::Editor")
```

A section editor is a ViewComponent. `initialize` takes `recording:` and `update_path:`. The class defines `param_key` and `permitted_attributes`. Text uses `RecordingStudioPresskits::Text::EditComponent` and `param_key` `:text`.

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index, the kit editor, the section editor, and owner preview are ViewComponents you can reuse or replace.

- Index: the current root's live kits. The heading is **My presskits**. **Presskit** with a Heroicons `plus` icon is first and left. Cards vs table is icon-only `FlatPack::ButtonGroup::Component` (`squares-2x2` / `table-cells`, aria labels only). Do not mint a Press kits toggle. This Flatpack pin's SegmentedButtons is text-only. Each card has a 16/9 cover. `cover_image_url` on the recordable supplies the image. A missing or unsafe URL uses the muted card color and a photo icon. Do not use Publishable's social image as the cover. Cards and the table open the kit editor.
- Empty index: what happened, and a way to make a kit.
- Kit URL: `GET press_kits/:id` requires edit access and redirects to the kit editor.
- Kit editor: **+ Section** (Heroicons `plus`, label Section) sits first on a row with `render_publishable_quick_actions`. The two-column grid starts under that row. Column one is the title form with a normal-size **Save**, then the section list. Each row is a `FlatPack::List::Item` inside `FlatPack::List::Component`. Move up and Move down patch the kit order and call `recording_studio_orderable_move!`. Each row links to that section. Column two renders every section through `section_component_for`. No in-page Preview button. No page title in the body. The page nav carries the kit name. Publishable's menu still has **View** and **Preview**. Types come from `picker_types`. Text is on that list once the host registers it. No empty-state tray on edit.
- Section editor: one section. Column one renders the registered editor, or the type label when none is registered, plus **Remove**. Column two renders that section only.
- Owner preview: the same public walk of children, on the default layout, for an authenticated owner. Back returns to the kit editor. A kit that is not live stays hidden from logged-out visitors.

Default-layout chrome is back, close, and page actions. Access stays in the right slot. Do not put Sign in, Sign out, or Root Switchable there — core owns back and close.

One primary action per page: **Presskit** (Heroicons plus) on the index, **Create** on the new form, **Save** on kit edit. Publish state stays on Publishable's own action. Do not hand-roll a second publish system.

## Public

A live kit is readable without signing in. Publishable serves `/published/:uuid/:slug` (override the path only if it still includes `:uuid`). `.to` sets `public_layout: "recording_studio_presskits/blank"`. That layout is a document and the kit: no back, no close, and no TopNav. View and the publish menu Preview both use it. Owner preview stays on `recording_studio/default_layout`.

Logged-out visitors get a 404 for a kit that is not currently published. An authenticated owner can still open the owner preview on the default layout.

Use `PressKit.indexable` / `indexable?` for public lists. A kit is indexable when it is currently published, not trashed, not marked noindex, and has a canonical or public URL.

## Admin

This gem registers one Admin section, `press_kits`, with two list widgets: live kits (`PressKit.indexable`) and kits that are not live yet. Enable it on your admin root. There is no vanity total.

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
| Publishable | `v0.3.1` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.2 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, the kit editor, owner preview, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. The same override passes Flatpack 0.1.133 `anchor_href` (core still stores the close path in `page_nav_anchor_url`) so the close X shows next to back. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, Publishable, and this gem so that layout is not an unstyled box.

The public kit view uses `recording_studio_presskits/blank` instead. Do not use Publishable's empty TopNav there. Do not insert Sign in, Sign out, or Root Switchable into PageNav — core owns back/close on the default layout. Access stays in the slot on signed-in workspace screens and owner preview. Cards, table, the kit editor, public show, owner preview, and Admin live in `docs/dummy-screenshots/`. After seed: `press-kit-index-cards.png`, `press-kit-index-table.png`, `workspace-kit-edit.png`, `workspace-kit-show.png`, `public-press-kit-show.png` (logged-out Spring launch), `owner-preview-unpublished.png` (owner preview of Autumn recap), and `admin-press-kits.png` (live vs not-live). Do not recapture dummy home.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one published kit titled **Spring launch** and one unpublished kit titled **Autumn recap**. No seeded fake sections. Dummy Workspace enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. Dummy `FakeBlock` stays test-only: it enables Trashable so remove is testable, it is excluded from the add dropdown, and it does not enable Publishable. The seeded admin user gets Accessible owner access on the workspace and the admin root.

## Cloud Agent boot

Cloud Agent Builds run `.cursor/install.sh`, then `.cursor/fetch-skills.sh`.
The install hook provisions a cold image. On a warm snapshot it skips apt,
ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are
already usable. Fetch-skills always runs last. `.cursor/start.sh` starts
PostgreSQL on each boot. Rebuild with Draft off to load a new pack. See
[Cursor skills in Cloud Agents](docs/cursor-skills.md).

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
