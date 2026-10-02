# Recording Studio Press Kits

A press kit is the folder you fill. Later addons drop in the sections — bio, downloads, logos. This gem is the container only.

Kits sit under your workspace. You can have many. You publish the kit, not each block. This slice ships the authenticated editor, a public page for a live kit, an owner preview of a kit that is not live yet, and Admin widgets for live vs not-live work.

## Install

Add the gem next to Recording Studio 4.2, Accessible, Admin 2.0, Publishable 0.3, and the three mixins PressKit already opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.10.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.0"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.1"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "0.4.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.133"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.10"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_orderable", "~> 0.2"
gem "recording_studio_trashable", "~> 0.4"
gem "recording_studio_duplicatable", "~> 0.4"
gem "recording_studio_publishable", "~> 0.3"
gem "recording_studio_attachable", "~> 0.4"
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
bin/rails generate recording_studio_attachable:install
bin/rails generate recording_studio_attachable:migrations
bin/rails active_storage:install
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

`RecordingStudioPresskits::Text`, `RecordingStudioPresskits::Images`, and `RecordingStudioPresskits::QuoteSection` are the sections this gem ships. Add them to the host `recordable_types`, then run `rails generate recording_studio_presskits:migrations` and migrate. Text stores HTML from FlatPack's content editor (`preset: :content`, `toolbar: :standard`). The kit editor's preview column and the public page render that HTML. The Text section editor hides its preview. The row label is the first line of text, with tags stripped. Trashable is on. Orderable stays on the kit. Publishable stays off the section. FlatPack's engine importmap pins TipTap, including the content preset. A host that skips that importmap has to pin those packages itself.

Images stores an optional caption. Photos are Attachable image attachments under that section recording, so one section holds many images. Attachable stays off PressKit. The editor uploads from an Upload button after Cancel and returns to the section. Removing one photo calls Attachable's remove and stays on the editor. That remove trashes the attachment recording, so Trashable is on `RecordingStudioAttachable::Attachment`. The kit preview and the public page render the caption and the images. Depend on `recording_studio_attachable`, `~> 0.4`, mount that engine, and wire Active Storage direct uploads.

Quotes stores nothing on the section. Each quote is a child recording with `body`, `name`, and optional `role` and `organisation`. The section editor is an orderable list in column one. Column two previews the saved quotes with the same component as the public page. The row is the name, or the start of the quote when the name is blank. Add quote opens that quote's edit screen. Orderable is on the quote section for its quotes. Attachable is on Quote for one image, and the upload stays on the quote screen. Publishable stays off both. A blank body is left off the preview and the public page. Add `"RecordingStudioPresskits::QuoteSection"` and `"RecordingStudioPresskits::Quote"` to `recordable_types` and migrate. Quote stays off the + Section menu because its parent is the quote section.

The kit editor's preview column and the public page walk children in order and render each type's component. Text, Images, and Quotes are registered. A later addon still registers its own component.

```ruby
RecordingStudioPresskits.register_section_component("SomeSection", "SomeSection::Component")

RecordingStudioPresskits.register_section_editor("SomeSection", "SomeSection::Editor")
```

A section editor is a ViewComponent. `initialize` takes `recording:` and `update_path:`. The class defines `param_key` and `permitted_attributes`. Define `preview?` and return false to hide the preview and use one full-width column. Define `form?` and return false to skip the shared section form and the Update button. Text uses `RecordingStudioPresskits::Text::EditComponent`, `param_key` `:text`, and `preview?` false. Images uses `RecordingStudioPresskits::Images::EditComponent`, `param_key` `:images`, and `preview?` false. Quotes uses `RecordingStudioPresskits::QuoteSection::EditComponent`, `param_key` `:quote_section`, and `form?` false. It keeps the default two-column preview.

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index, the kit editor, the section editor, and owner preview are ViewComponents you can reuse or replace.

- Index: the current root's live kits. The heading is **My presskits**. **Presskit** with a Heroicons `plus` icon is first and left. Cards vs table is icon-only `FlatPack::ButtonGroup::Component` (`squares-2x2` / `table-cells`, aria labels only). Do not mint a Press kits toggle. This Flatpack pin's SegmentedButtons is text-only. Each card has a 16/9 cover. `cover_image_url` on the recordable supplies the image. A missing or unsafe URL uses the muted card color and a photo icon. Do not use Publishable's social image as the cover. Cards and the table open the kit editor.
- Empty index: what happened, and a way to make a kit.
- Kit URL: `GET press_kits/:id` requires edit access and redirects to the kit editor.
- Kit editor: the page heading is the kit name. **+ Section** (Heroicons `plus`, label Section, primary button) sits first on a row with `render_publishable_quick_actions`. The two-column grid starts under that row. There is no title form and no **Save** on this page. Column one is one `FlatPack::Card` around one `FlatPack::List` (`orderable: true`, `divider: true`). Each section is a `FlatPack::List::Item`. The link text is the section type, such as **Text**, and it opens that section. The list icon slot is Heroicons `arrows-up-down`. FlatPack's `flat-pack--list-orderable` controller does the drag. This FlatPack pin's `saveOrder` checks `hasOrderablePathValue`, which is never defined, so the fetch does not run. `list:reordered` posts `recording_id` and `before_recording_id` or `after_recording_id`, and that calls `recording_studio_orderable_move!`. Remove is an icon-only trash button. It posts delete and `SectionsController#destroy` calls `recording_studio_trashable_trash!`. Column two renders every section through `section_component_for` inside one `FlatPack::Card`. No in-page Preview button. The page nav also carries the kit name. Publishable's menu still has **View** and **Preview**. Types come from `picker_types`. Text is on that list once the host registers it. No empty-state tray on edit.
- Section editor: a page heading is the section type, such as **Text**. **Update** (primary) and **Cancel** (default button) sit above the grid. Cancel returns to the kit editor. The default grid is two columns. Column one is the registered editor, full width of that column, or the type label when none is registered. Column two renders that section's saved HTML inside a `FlatPack::Card`, lined up with the field. An editor class can define `preview?` and return false to drop the preview and use one full-width column. Text does that. The Text field is the FlatPack content WYSIWYG with no field label. The kit list trashes a section with the trash icon through `recording_studio_trashable_trash!`. **+ Access** stays off this page.
- Owner preview: the same public walk of children, on the default layout, for an authenticated owner. Back returns to the kit editor. A kit that is not live stays hidden from logged-out visitors.

Default-layout chrome is back, close, and page actions. **+ Access** is in the right slot on the kit editor only. Index, the new form, the section editor, and owner preview leave that slot empty. Do not put Sign in, Sign out, or Root Switchable there. Core owns back and close.

Primary buttons: **Presskit** (Heroicons plus) on the index, **Create** on the new form, **+ Section** on kit edit, **Update** on a section editor. Publish state stays on Publishable's own action. Do not hand-roll a second publish system.

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
| Accessible | `v0.10.0` |
| Admin | `2.0.0` |
| Root Switchable | `v0.5.0` |
| FlatPack | `v0.1.133` |
| Orderable | `0.2.0` |
| Trashable | `0.4.0` |
| Duplicatable | `0.4.0` |
| Publishable | `v0.3.1` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.2 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, the kit editor, owner preview, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. The same override passes Flatpack 0.1.133 `anchor_href` (core still stores the close path in `page_nav_anchor_url`) so the close X shows next to back. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, Publishable, and this gem so that layout is not an unstyled box.

The public kit view uses `recording_studio_presskits/blank` instead. Do not use Publishable's empty TopNav there. Do not insert Sign in, Sign out, or Root Switchable into PageNav. Core owns back and close on the default layout. **+ Access** is in the slot on the kit editor only. Cards, table, the kit editor, public show, owner preview, and Admin live in `docs/dummy-screenshots/`. After seed: `press-kit-index-cards.png`, `press-kit-index-table.png`, `workspace-kit-edit.png`, `workspace-kit-show.png`, `public-press-kit-show.png` (logged-out Spring launch), `owner-preview-unpublished.png` (owner preview of Autumn recap), and `admin-press-kits.png` (live vs not-live). Do not recapture dummy home.

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
