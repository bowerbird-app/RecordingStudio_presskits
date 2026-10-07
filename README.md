# Recording Studio Press Kits

A press kit holds ordered sections. Each section is a `RecordingStudioPresskits::KitSection` recording. The child under that recording is the content, such as text, images, or quotes. A later addon registers its own content type under a kit section.

Kits sit under your workspace. You can have many. You publish the kit, not each block. This gem ships the authenticated editor, a public page for a live kit, an owner preview of a kit that is not live yet, and Admin widgets for live vs not-live work.

## Install

Add the gem next to Recording Studio 4.2, Accessible 0.11, Admin 2.0, Publishable 0.4, and the three mixins PressKit already opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.2"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.11.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.0.4"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.5"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.4.4"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.3"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.4.2"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.7.1"
gem "recording_studio_external_embed", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.3"
gem "recording_studio_video", github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.200"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.11"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_orderable", "~> 0.2"
gem "recording_studio_trashable", "~> 0.4"
gem "recording_studio_duplicatable", "~> 0.4"
gem "recording_studio_publishable", "~> 0.4"
gem "recording_studio_attachable", "~> 0.7"
gem "recording_studio_external_embed", "~> 0.1.1"
gem "recording_studio_video", "~> 0.1.0"
gem "flat_pack", ">= 0.1.200"
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
bin/rails generate recording_studio_video:install
bin/rails generate recording_studio_video:migrations
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
    "RecordingStudioPresskits::KitSection",
    "RecordingStudioPresskits::Text",
    "RecordingStudioPresskits::Images",
    "RecordingStudioPresskits::QuoteSection",
    "RecordingStudioPresskits::Quote",
    "RecordingStudioPresskits::VideoSection",
    "RecordingStudioVideo::Video",
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

Orderable on the kit allows only `RecordingStudioPresskits::KitSection`. Position is a column on the kit section recording. Reorder history is an event on the kit. A quote section orders its own quotes. Content recordings are not ordered as kit children.

Duplicatable's README takes `include_children` as an array of types, not `true`. Leaving both include and exclude unset copies nothing. `exclude_children: []` copies the kit section and everything under it, including nested quotes.

Core 4.2 stores type names as the class name. There is no public alias. A content recordable that belongs in a press kit names the kit section as its parent.

```ruby
allowed_parent_types: ["RecordingStudioPresskits::KitSection"]
```

Create kits and change them with public helpers. Do not insert Recording or Event rows by hand.

```ruby
root = RecordingStudio.root_recording_for(workspace)
kit_recording = root.record(RecordingStudioPresskits::PressKit) do |kit|
  kit.title = "Spring launch"
end

root.revise(kit_recording) do |kit|
  kit.title = "Spring launch, take two"
  kit.description = "Doors at noon."
end

kit_recording.log_event!(action: "noted")
```

The header is the press kit. `title` is required. `description` is an optional short line, 280 characters at most, and a blank one is stored as nothing. It is not a child recording, so it cannot be trashed or reordered. The kit editor lists it as Header and links to the header screen, which saves both fields with `revise`. Creating a kit still sets the title only.

Create a section with `RecordingStudioPresskits.create_section!`. That call records a kit section under the kit, then records the chosen content type under the kit section, in one transaction. A failed content write leaves no kit section behind. Title and subtitle belong to the kit section. A content default belongs to the registered `prepare` hook.

```ruby
RecordingStudioPresskits.create_section!(
  press_kit_recording: kit_recording,
  content_type: "RecordingStudioPresskits::Text",
  actor: current_user,
  title: "The story",
  subtitle: "A short line"
)
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

A section is always a kit section. `section?` is true only for `RecordingStudioPresskits::KitSection`. `register_section` puts a content type on the + Section menu and stores its component, its editor, and an optional `prepare` hook. Registering the type does not make that type a section.

```ruby
RecordingStudioPresskits.register_section(
  "SomeContent",
  component: "SomeContent::Component",
  editor: "SomeContent::Editor",
  prepare: lambda { |recordable, title: nil, **|
    recordable.body = "Opening line." if recordable.body.blank?
  }
)

RecordingStudioPresskits.configure do |config|
  config.excluded_picker_types = ["FakeBlock"]
end
```

The content class still declares that parent, and the host still lists the class in `recordable_types`. If `picker_types` is empty, + Section is a disabled button. No empty menu box.

`KitQuery.sections_for` returns the ordered kit sections under a press kit. `KitQuery.section_for` finds one of those by id. `KitQuery.section_content` returns the content child of a kit section. The kit editor, the preview, and the public page walk kit sections in order. `SectionFrameComponent` renders the kit section title and subtitle, then the component registered for the content type. The content component does not render that title or subtitle. A subtitle with no title is a muted line above the content. A publish recording under the kit is not a section and is not in the kit's orderable children.

`RecordingStudioPresskits::Text` stores HTML from FlatPack's content editor (`preset: :content`, `toolbar: :standard`). A new text section starts with `Text.opening_body` when the body is blank. The text editor shows the body only. Title and Subtitle are the kit section fields on the same screen. The text editor hides its preview. Trashable is on the text recording and on the kit section. Orderable stays on the kit for kit sections. Publishable stays off both. FlatPack's engine importmap pins TipTap, including the content preset. A host that skips that importmap has to pin those packages itself.

`RecordingStudioPresskits::Images` stores no heading of its own. Photos are Attachable image attachments under the images recording, so one section holds many images. Attachable stays off PressKit and off KitSection. The editor shows Update above Title and Subtitle on the kit section. Upload and the photo editor sit under that form, and the upload returns to the section. `attachment_collection_editor` edits each photo's caption, credit, and alt text on the images recording. The row preview keeps the file's proportions. Trash on a photo uses Attachable's remove and returns to the section. That remove trashes the attachment recording, so Trashable is on `RecordingStudioAttachable::Attachment`. Depend on `recording_studio_attachable`, `~> 0.7`, mount that engine, and wire Active Storage direct uploads. The images editor keeps a preview column. The card stays off until the section has a title, a subtitle, or a photo. The card has no header.

Quotes use two recordings under the kit section. `RecordingStudioPresskits::QuoteSection` orders its quotes and stores no heading. Each `RecordingStudioPresskits::Quote` has `body`, `name`, and optional `role` and `organisation`. A new quotes section leaves the kit section title blank. A kit migrated from 0.16 copies the heading Quotes onto the kit section, because that is the heading the public page showed before. The section page uses the shared section editor. Update sits above Title and Subtitle. **+ Quote** and the quote list sit under that form in column one. + Quote is a primary button with a Heroicons plus icon and the label Quote. Column two, the kit preview, and the public page render each saved quote with `FlatPack::Quote::Component` at `size: :lg`. The citation is the name, role, and organisation. The row shows the quote, truncated to the column, with the name underneath. A blank quote uses Quote on the first line. A blank name leaves the second line off. + Quote opens that quote's edit screen. Orderable is on the quote section for its quotes. Attachable is on Quote for one image, and the upload stays on the quote screen. Publishable stays off the quote section and the quote. A blank body is left off the preview and the public page. Quote stays off the + Section menu because its parent is the quote section.

A video section is the same shape. Press Kits owns `RecordingStudioPresskits::VideoSection`, an empty recording under the kit section. Recording Studio Video owns each `RecordingStudioVideo::Video` child. External Embed owns the provider embed. YouTube ships with External Embed. Another provider appears when the host registers it. Press Kits does not register Vimeo. The section includes Trashable and Videos. It does not include Orderable, so videos stay in the order they were added. Title and subtitle stay on the kit section. + Video sits under the heading form and links to a new video. That screen uses Video's field helper. A saved video also shows Video's player. Removing a video trashes that recording. Removing the section trashes the kit section and the videos under it. Neither path deletes rows.

The kit list row label is the content type, such as Text, Images, or Quotes. The kit section title is the heading on the preview and the public page. The page nav title of a section editor is the kit section title when one is set, and the content type label otherwise. The heading on the section editor page is the content type label.

A content editor is a ViewComponent. `initialize` takes the content recording as `recording` and the form path as `update_path`. The class defines `param_key` and `permitted_attributes`. It does not build the page. `SectionEditorComponent` is the two-column template for every section. Column one is the heading form, then anything that section adds under it. The heading form is Update, then Title, Subtitle, then extra fields from the content editor. That form uses Flatpack's unsaved-changes controller. Update is `style: :default` and the submit target. It stays default while the fields match the saved values and turns primary when they do not. Define `self.below?` and return true when the editor cannot sit inside that form. The template then renders `section_actions` and the editor under the form. Text leaves `below?` unset, so Body is an extra field under Subtitle. Images and Quotes return true from `below?`. Images draws Upload and the photo editor under the form. Quotes draws + Quote through `section_actions`, then the quote list. Text uses `RecordingStudioPresskits::Text::EditComponent`, `param_key` `:text`, and permitted attribute `:body`. Images uses `RecordingStudioPresskits::Images::EditComponent`, `param_key` `:images`, and no permitted attributes. Quotes uses `RecordingStudioPresskits::QuoteSection::EditComponent`, `param_key` `:quote_section`, and `below?` true. Video uses `RecordingStudioPresskits::VideoSection::EditComponent`, `param_key` `:video_section`, permitted attributes empty, and `below?` true. + Video is a link, not a create that records a blank video.

When Recording Studio API is loaded, a press kit exposes show. Its payload keys are `title` and `description`. Those fields stay writable on the header screen. The press kit also exposes `create_section` and `reorder_sections`. `create_section` takes `content_type`, `title`, and `subtitle` and calls `create_section!`. `reorder_sections` takes `ordered_recording_ids` and calls `recording_studio_orderable_reorder!`. A kit section exposes index, show, and update. Its payload keys are `title`, `subtitle`, `content_type`, and `content_id` for every section. `:videos` is declared on that type as well. The `videos` array is present only when the content is a video section. Each entry has `title`, `url`, `description`, `provider`, `canonical_url`, and `content_type`. A video section's own show payload is that `videos` array. Press Kits does not register `RecordingStudioVideo::Video` with the API. Video already does, including the derived provider fields. The kit section also exposes `remove_section`, which trashes the kit section. Trashable then trashes the content under it. There is no generic kit section create, because a kit section without content would break the one-content rule, and no kit section destroy. Text exposes show and update for `body`. The member actions are `POST .../press_kits/:id/actions/create_section`, `POST .../press_kits/:id/actions/reorder_sections`, and `POST .../kit_sections/:id/actions/remove_section`.

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index, the kit editor, the header screen, the section editor, and owner preview are ViewComponents you can reuse or replace.

- Index: the current root's live kits. The heading is **My presskits**. **Presskit** with a Heroicons `plus` icon is first and left. Cards vs table is icon-only `FlatPack::ButtonGroup::Component` (`squares-2x2` / `table-cells`, aria labels only). Do not mint a Press kits toggle. This Flatpack pin's SegmentedButtons is text-only. Each card has a 16/9 cover. `cover_image_url` on the recordable supplies the image. A missing or unsafe URL uses the muted card color and a photo icon. Do not use Publishable's social image as the cover. Cards and the table open the kit editor.
- Empty index: what happened, and a way to make a kit.
- Kit URL: `GET press_kits/:id` requires edit access and redirects to the kit editor.
- Kit editor. The page heading is the kit name. **+ Section** (Heroicons `plus`, label Section, primary button) sits first on a row with `render_publishable_quick_actions`. Each menu item is a registered content type. Text uses `document-text`, Images uses `photo`, Quotes uses `chat-bubble-bottom-center-text`, and Video uses `video-camera`. A host content type defines `self.section_menu_icon` to supply its own. A type without one stays a label. Choosing one calls `create_section!` and opens the new kit section. The two-column grid starts under that row. There is no title form and no **Save** on this page. Column one is one `FlatPack::Card`. **Header** is the first row. It is a `FlatPack::List::Item` with Heroicon `bars-3-bottom-left` and no remove, and it opens the header screen. The header is the press kit itself, so it cannot be dragged or removed. A blank description is stored as nothing. 280 characters is the limit. Creating a kit still asks only for the name. + Section stays the only primary button on this page. When there are sections, they follow in that same card as one `FlatPack::List` (`orderable: true`, `divider: true`). Header stays outside that list. Each row is a kit section. The link text is the content type, such as **Text**, and it opens that kit section. The list icon slot is Heroicons `arrows-up-down`. FlatPack's `flat-pack--list-orderable` controller does the drag. This FlatPack pin's `saveOrder` checks `hasOrderablePathValue`, which is never defined, so the fetch does not run. `list:reordered` posts `recording_id` and `before_recording_id` or `after_recording_id`, and that calls `recording_studio_orderable_move!` on kit section ids. Remove is an icon-only trash button. It posts delete and `SectionsController#destroy` trashes the kit section. Column two is one `FlatPack::Card` when there is a short description or a kit section with a title, a subtitle, or content that would show. The description comes first, then every visible kit section through `SectionFrameComponent`. A kit with neither has no preview card. No in-page Preview button. The page nav also carries the kit name. Publishable's menu still has **View** and **Preview**. Types come from `picker_types`. No empty-state tray on edit.
- Header screen: the page heading is **Header**. Back is **Back to kit** and returns to the kit editor. **Update** (primary) and **Cancel** (default button) sit above the grid. The grid is two columns, the same shape as a section editor. Column one is Title and Short description. Title is required. Short description is optional, with a 280 character count. Column two is a `FlatPack::Card` that shows that title and short description. Saving stays on this screen and uses `revise`. **+ Access** stays off.
- Section editor. The page nav title is the kit section title when one is set, and the content type label otherwise. The on-page heading is the content type, such as **Text**. **Title** and **Subtitle** belong to the kit section. The grid is always two columns. Column one is one heading form for every section: **Update**, then Title, Subtitle, and extra fields. Update starts in the default style and turns primary when a field in that form no longer matches the saved value. Putting the saved text back returns it to default. There is no Cancel button. Back returns to the kit editor. Custom UI sits under that form. Quotes puts **+ Quote** (Heroicons `plus`, label Quote, primary button) there, then the quote list. Video puts **+ Video** (Heroicons `plus`, label Video, primary link) there, then the video list. Images puts Upload there, then the photo editor. Column two stays in the grid. It renders `SectionFrameComponent` inside a `FlatPack::Card` with no card header when the section has a title, a subtitle, or content that would show. Otherwise that column is empty. The Text field is the FlatPack content editor, labeled Body, and it sits in the heading form under Subtitle. The kit list trashes the kit section with the trash icon through `recording_studio_trashable_trash!`. **+ Access** stays off this page.
- Owner preview: the same public page, on the default layout, for an authenticated owner. Back returns to the kit editor. A kit that is not live stays hidden from logged-out visitors.

Default-layout chrome is back, close, and page actions. **+ Access** is in the right slot on the kit editor only. Index, the new form, the header screen, the section editor, and owner preview leave that slot empty. Do not put Sign in, Sign out, or Root Switchable there. Core owns back and close.

Primary buttons: **Presskit** (Heroicons plus) on the index, **Create** on the new form, **+ Section** on kit edit, and **Update** on the header screen. A section editor's **Update** starts in the default style and turns primary when the heading form changes. Publish state stays on Publishable's own action. Do not hand-roll a second publish system.

## Public

A live kit is readable without signing in. Publishable serves `/published/:uuid/:slug` (override the path only if it still includes `:uuid`). `.to` sets `public_layout: "recording_studio_presskits/blank"`. That layout is a document and the kit: no back, no close, and no TopNav. The page title is the kit name. A short description, when the kit has one, sits under that title. View and the publish menu Preview both use it. Owner preview stays on `recording_studio/default_layout`.

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

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

| Field    | Value           |
|----------|-----------------|
| Email    | admin@admin.com |
| Password | Password        |

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `v4.2.2` |
| Accessible | `v0.11.1` |
| Admin | `v2.0.4` |
| Root Switchable | `v0.5.3` |
| FlatPack | `v0.1.200` |
| Attachable | `v0.7.1` |
| Orderable | `v0.2.5` |
| Trashable | `v0.4.4` |
| Duplicatable | `v0.4.3` |
| Publishable | `v0.4.2` |
| External Embed | `v0.1.3` |
| Video | `v0.1.0` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.2 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, the kit editor, owner preview, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack `anchor_href` (core still stores the close path in `page_nav_anchor_url`) so the close X shows next to back. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, Publishable, Attachable, and this gem so that layout is not an unstyled box.

The public kit view uses `recording_studio_presskits/blank` instead. Do not use Publishable's empty TopNav there. Do not insert Sign in, Sign out, or Root Switchable into PageNav. Core owns back and close on the default layout. **+ Access** is in the slot on the kit editor only. Cards, table, the kit editor, the header screen, public show, owner preview, and Admin live in `docs/dummy-screenshots/`. After seed: `press-kit-index-cards.png`, `press-kit-index-table.png`, `workspace-kit-edit.png`, `workspace-header-edit.png`, `workspace-kit-show.png`, `public-press-kit-show.png` (logged-out Spring launch), `owner-preview-unpublished.png` (owner preview of Autumn recap), and `admin-press-kits.png` (live vs not-live). Do not recapture dummy home.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one published kit titled **Spring launch**, with a short description, and one unpublished kit titled **Autumn recap**. No seeded sections. Dummy Workspace enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. Dummy `FakeBlock` stays test-only. Its parent is a kit section. It enables Trashable so remove is testable, it is excluded from the add dropdown, and it does not enable Publishable. Its `prepare` hook sets the block title from the create heading, or to Block when that heading is blank. The seeded admin user gets Accessible owner access on the workspace and the admin root.

## Cloud Agent boot

Cloud Agent Builds run `.cursor/install.sh`, then `.cursor/fetch-skills.sh`.
The install hook provisions a cold image. On a warm snapshot it skips apt,
ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are
already usable. If `RAILS_MASTER_KEY` is set, `install.sh` writes gitignored
`test/dummy/config/master.key` so dummy credentials decrypt. Fetch-skills always
runs last. `.cursor/start.sh` starts PostgreSQL on each boot. Rebuild with
Draft off to load a new pack. See
[Cursor skills in Cloud Agents](docs/cursor-skills.md).

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
