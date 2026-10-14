# Recording Studio Press Kits

A press kit holds ordered sections. Each section is a `RecordingStudioPresskits::KitSection` recording. The child under that recording is the content, such as text, images, or quotes. A later addon registers its own content type under a kit section.

Kits sit under your workspace, or under any recordable that includes Press kits. You can have many. You publish the kit, not each block. This gem ships the authenticated editor, a public page for a live kit, an owner preview of a kit that is not live yet, and Admin widgets for live vs not-live work.

## Install

Add the gem next to Recording Studio 4.4, Accessible 0.14, Admin 2.0, Publishable 0.7, Downloadable 0.3, Company 0.3, Location 0.4, and the mixins PressKit already opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.5.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.15.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.2.0"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.3.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.8.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.5.0"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.8.0"
gem "recording_studio_downloadable", github: "bowerbird-app/RecordingStudio_downloadable", tag: "v0.4.0"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.15.0"
gem "recording_studio_company", github: "bowerbird-app/RecordingStudio_company", tag: "v0.4.0"
gem "recording_studio_lists", github: "bowerbird-app/RecordingStudio_lists", tag: "v0.5.0"
gem "recording_studio_location", github: "bowerbird-app/RecordingStudio_location", tag: "v0.6.0"
gem "recording_studio_external_embed", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.4"
gem "recording_studio_video", github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.1"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.235"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.15"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_orderable", "~> 0.3"
gem "recording_studio_trashable", "~> 0.8"
gem "recording_studio_duplicatable", "~> 0.5"
gem "recording_studio_publishable", "~> 0.8"
gem "recording_studio_downloadable", "~> 0.4"
gem "recording_studio_attachable", "~> 0.15"
gem "recording_studio_company", "~> 0.4"
gem "recording_studio_lists", "~> 0.5"
gem "recording_studio_location", "~> 0.4"
gem "recording_studio_external_embed", "~> 0.1.1"
gem "recording_studio_video", "~> 0.1.0"
gem "recording_studio_metrics", "~> 0.2"
gem "flat_pack", ">= 0.1.235"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_presskits:install
bin/rails generate recording_studio_presskits:migrations
bin/rails generate recording_studio_accessible:migrations
bin/rails generate recording_studio_orderable:install
bin/rails generate recording_studio_orderable:migrations
bin/rails generate recording_studio_trashable:install
bin/rails generate recording_studio_trashable:migrations
bin/rails generate recording_studio_duplicatable:install
bin/rails generate recording_studio_publishable:install
bin/rails generate recording_studio_publishable:migrations
bin/rails generate recording_studio_downloadable:install
bin/rails generate recording_studio_downloadable:migrations
bin/rails generate recording_studio_accessible:migrations
bin/rails generate recording_studio_attachable:install
bin/rails generate recording_studio_attachable:migrations
bin/rails generate recording_studio_company:install
bin/rails generate recording_studio_company:migrations
bin/rails generate recording_studio_location:install
bin/rails generate recording_studio_location:migrations
bin/rails generate recording_studio_lists:install --mount-path /
bin/rails generate recording_studio_lists:migrations
bin/rails generate recording_studio_video:install
bin/rails generate recording_studio_video:migrations
bin/rails active_storage:install
bin/rails generate recording_studio_admin:install
bin/rails db:migrate
```

The install generator mounts the user slice, writes `parent_root_type`, and enables `section :press_kits` when an `AdminRoot` model is already there. Duplicatable has no engine-owned schema. Publishable's install mounts that engine at `/` so live kits use `/published/:uuid/:slug`.

Lists ships with the gem. Register `RecordingStudio::Lists::List` and `RecordingStudio::Lists::ListItem`, and enable `:lists` on the host root (`RecordingStudio.enable_capability(:lists, on: Workspace)`). Mount `RecordingStudioLists::Engine` at `/` after the host routes so `/` stays the host home and the screens are `/lists`, `/lists/new`, and `/lists/:id`. The lists install generator defaults to `/recording_studio_lists`; pass `--mount-path /`. Decline its optional `config/recording_studio_lists.yml` prompt. Dummy enables `:lists` on Workspace only. The grid card renders `recording_studio_add_to_list` when Lists is loaded and `Current.actor` is present. Press kits do not create lists themselves.

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
    "RecordingStudioPresskits::FactsSection",
    "RecordingStudioPresskits::Fact",
    "RecordingStudioPresskits::VideoSection",
    "RecordingStudioPresskits::LocationSection",
    "RecordingStudioVideo::Video",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudio::AccessConstraint",
    "RecordingStudio::AccessRule",
    "RecordingStudioCompany::Company",
    "RecordingStudio::Lists::List",
    "RecordingStudio::Lists::ListItem",
    "RecordingStudio::Location::Location"
  ]
  config.require_recordable_declarations = true
end

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
end
```

The kit declares itself as a nested type under that root, then opts into Orderable, Trashable, Duplicatable, Publishable, Downloadable, Location, and Attachable with the current `.to` API only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path for these mixins. Do not enable Publishable or Downloadable on section children. Company is a host opt-in on the root, not on the kit. PressKit also enables Accessible `:action_audiences` so a kit can hold an `AccessRule` for who may view the full kit or download it. Enable `:action_audiences` on the host root too if the workspace should be able to narrow those audiences.

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
include RecordingStudio::Capabilities::Downloadable.to(
  source: :manifest,
  format: :zip,
  action: :"presskits.kit_download",
  export_scope: :public
)
include RecordingStudio::Capabilities::Location.to
include RecordingStudio::Capabilities::Attachable.to(
  allowed_content_types: ["image/*"],
  enabled_attachment_kinds: [:image],
  max_file_size: 10.megabytes,
  max_file_count: 1,
  auth_roles: { remove: :edit }
)

RecordingStudio.enable_capability(:action_audiences, on: self)
```

PressKit names only the host root as a parent. A host that wants kits under another recordable includes Press kits on that recordable. `.to` takes no options and calls `RecordingStudio::Capabilities.include_for(:press_kits)`. Installing the gem does not turn the capability on.

```ruby
include RecordingStudio::Capabilities::PressKits.to
```

The gem registers the capability when it boots, not inside `.to`:

```ruby
RecordingStudio.register_capability(
  :press_kits,
  source: "recording_studio_presskits",
  child_recordables: ["RecordingStudioPresskits::PressKit"]
)
```

Core then treats each recordable that includes the capability as an allowed parent (`extra_capability_parent_types_for`). Do not add a second parent list on the kit. A capability-owned child cannot sit under a shared root. Workspace is not a shared root, so kits still sit directly on the workspace.

`KitQuery.for_root` returns live kits anywhere under that root. The kit index, the editor, and the owner preview load kits through that query, so a kit under another recordable still opens.

On the host root, turn companies on when you want the company name on the kit card. Dummy Workspace uses one company per root:

```ruby
include RecordingStudio::Capabilities::Companies.to(allow: :one)
RecordingStudio.enable_capability(:action_audiences, on: self)
```

Orderable on the kit allows `RecordingStudioPresskits::KitSection`. KitQuery and the Reorder screen list only kit sections. The cover photo is a direct attachment, not an orderable child, so moving sections leaves it on the kit. Position is a column on the kit-section recordings. Reorder history is an event on the kit. A quote section orders its own quotes. An Images section orders its own attachments. Content recordings are not ordered as kit children.

Duplicatable's README takes `include_children` as an array of types, not `true`. Leaving both include and exclude unset copies nothing. `exclude_children: []` copies the kit section and everything under it, including nested quotes and image attachments. `AttachmentCopy` is the dup strategy for `RecordingStudioAttachable::Attachment`. It downloads the file and attaches a new blob, so a duplicated kit does not share bytes with the source. Duplicatable still suffixes the attachment `name` with ` (Copy)`. `original_filename` and alt text stay as they were. Quote images use the same copy.

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
  kit.brand_color = "#BFDBFE"
  kit.font_family = "serif"
end

kit_recording.log_event!(action: "noted")
```

The header is the press kit. `title` is required. `subtitle` is an optional line, 120 characters at most. `description` is an optional short line, 280 characters at most. A blank subtitle, description, or release date is stored as nothing. `release_date` is an optional date. `brand_color` is an optional `#RRGGBB` and `font_family` is an optional `sans`, `serif`, or `mono`. Nil on either field means inherit: the parent press center's value when `RecordingStudioPressCenters` is loaded, otherwise `#333333` and `sans`. An explicit `#333333` or `sans` is stored, so a kit can force the default over a branded center. Each field resolves on its own. The cover photo is a separate direct image attachment on the kit, the same shape as a quote image. On the kit editor, title, subtitle, and description edit in place on the card and save through the header update path with `revise`. The header screen saves the release date, brand, font, and the optional kit location on that same path. The release date input is `FlatPack::DateInput`, named `press_kit[release_date]`. A request that omits a field leaves the stored value. Upload and remove for the cover photo are their own forms on that screen. Creating a kit still sets the title only.

When the host root enables companies (`allow: :one`), `Cover::Company` looks up `RecordingStudioCompany.company(root)` and the card shows the company name. No capability, or no company, hides that line. One optional Location child on the kit (not a section) is the place. There is no location string on the kit. Below 640px of the card, its icon and `display_name` sit under the short description. A blank short description puts that line under the title and subtitle. From 640px, that place joins the release line and the stacked line hides. `KitLocation` looks that child up and writes it. The header screen edits that place with `recording_studio_location_search_fields`. Blank fields clear it. A Location section is a different parent: places there hang off `LocationSection`, not the kit.

The cover photo sits in the top of the card. PressKit includes `Attachable.to` for one `image/*` file. `CoverImage` resolves the first direct image through `DirectImages`. `Cover::Image` paints it with `object-cover` inside `aspect-[430/368]`. With no photo, that frame is a muted surface. The header screen uploads and removes that file itself. There is no library picker and no second photo model.

`RecordingStudioPresskits::Cover::Component` is that card. The only size is `:card`. An unknown size, including the old `:hero` and `:preview`, renders the card. The layout follows the card's own width (`@container`): stacked below 640px, and a wide row from 640px. Pass a kit recording, or the title, subtitle, description, brand colour, and font. The **Press kit** badge (`recording_studio_presskits.cover.eyebrow`) is `FlatPack::Badge` `style: :default` on `FlatPack::Overlay`, top left with the medium inset. Overlay only places it. On the rounded theme that badge is a muted surface (`#e5e5e5`) with `#333` text and a surface border. It does not follow the brand. The **View** button uses the resolved brand colour, with `Cover::Contrast` for the label. The card body shows the company name, the location, the title, the subtitle, and the short description. From 640px of the card's own width, one muted line sits under that description. It is `hidden` until `@min-[640px]:flex`, wraps, and leaves a gap between pieces. A calendar icon and small text show the date when `release_date` is set, for example Released 14 Oct 2026. The kit location follows on that same line: `FlatPack::Shared::IconComponent` with the place's icon (a venue defaults to map-pin) and `display_name`. Each piece shows only when it is present. Both blank hides the line. A narrower card keeps the location on its own line and does not show the date. A host page that renders this card, or the full kit, follows [Displaying press kits in a host](#displaying-press-kits-in-a-host).

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

A live kit can be downloaded as a zip. Downloadable owns the package, the button, and who may fetch it. Presskits owns the public manifest and the publish glue. Do not write package rows by hand.

The zip holds every direct photo — cover first, then Images-section attachments, original files, unique filenames such as `cover-harbour-gallery.jpg` — plus `kit.txt`. That text file is the public kit only: title, short description, company, location, date, section titles and subtitles, public text, quotes with attribution, credits, and image caption, credit, and alt. Drafts, unpublished revisions, trashed photos, and private notes stay out. `DirectImages` is the same helper the public page uses.

Presskits subscribes to Publishable's after-commit events in an engine initializer (`RecordingStudioPublishable.subscribe`). Publish calls `downloadable_generate!`. Unpublish calls `downloadable_invalidate!(immediate: true)`. A revision to a live kit rebuilds. Downloadable's own debounce still covers ordinary content writes. Unpublished kits do not generate.

```ruby
kit_recording.downloadable_generate!(
  action: kit_recording.downloadable_action,
  export_scope: kit_recording.downloadable_export_scope
)
kit_recording.downloadable_invalidate!(immediate: true)
kit_recording.recordable.downloadable_available_for?(actor: current_user, action: :"presskits.kit_download")
```

`downloadable_available_for?` is true only while the kit is currently published. Anyone who may take the action can trigger a build when the zip is missing or stale (Downloadable rate-limits and dedupes that). Authorization is Accessible `authorized_action?` plus that availability gate.

Default audience for `:"presskits.kit_download"` is public — anyone, including a logged-out visitor, can take a live kit. `allowed` is `public` / `signed_in` / `granted` plus any audience the host registered before boot. Granted roles stay `download`, `edit`, and `admin` — not `view` alone. Host and workspace Accessible constraints still apply: when Public is not allowed, Accessible falls back to granted and keeps that choice. Hosts overwrite the default:

```ruby
RecordingStudioAccessible.configure do |config|
  config.action_audiences[:"presskits.kit_download"] = {
    allowed: %i[public signed_in granted],
    default: :public,
    granted_roles: %i[download edit admin],
    granted_override: true,
    manage_role: :edit
  }
end
```

Kit owners and editors (`manage_role: :edit`) change who may download from **Downloads** on the kit editor toolbar. That screen is a `pk-editor` modal with one heading: PageTitle **Downloads**, subtitle "Who can download this press kit". There is no small chrome title and no repeated field label (the RadioGroup keeps an `aria-label`). Audience is a Flatpack RadioGroup `variant: :inline` with icons, one option per Accessible `audience_options_for` after host and workspace constraints. Defaults: Anyone `globe-alt`, Signed in `user`, People with access `lock-closed`, custom audiences `user-group`. Hosts set `config.download_audience_icons` or i18n `recording_studio_presskits.downloads.audience_icons`. Save calls `set_audience!`. When Accessible fell back to granted, that option is selected and an info alert says the one in force is selected. Dummy Workspace enables `action_audiences`. Hosts that want extra rows `register_audience` before boot so they land in `allowed`.

Downloadable re-checks the audience on every request to the package path (`/recording_studio_downloadable/recordings/:id/package` and `.../package/status`). Switching from Anyone to Signed in immediately refuses an anonymous GET to that path, even when a zip is already built — no redirect to the blob, no new build. A signed ActiveStorage blob URL already issued is a bearer link until it expires. Downloadable uses `ActiveStorage.urls_expire_in` when that is positive, otherwise `SIGNED_URL_EXPIRES_IN` (5 minutes). People with access means a `download`, `edit`, or `admin` grant on the kit's root, not `view` alone. A download-only grant needs `:download` in the root's `accessible_roles`; edit and admin already count. The public **Download kit** button follows the signed-in visitor, not a leftover `Current.actor`.

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

`KitQuery.sections_for` returns the ordered kit sections under a press kit. `KitQuery.section_for` finds one of those by id. `KitQuery.section_content` returns the content child of a kit section. The kit editor, the preview, and the public page walk kit sections in order. `SectionFrameComponent` renders the kit section title and subtitle, then the component registered for the content type. The content component does not render that title or subtitle. A blank title uses `section_heading`, which falls back to `default_section_heading`: the content type label, such as Text, Images, Quotes, Facts & Figures, Video, or Location. The subtitle sits under that heading. The saved title stays blank. A publish recording under the kit is not a section and is not in the kit's orderable children.

`RecordingStudioPresskits::Text` stores HTML from FlatPack's content editor (`preset: :content`, `toolbar: :standard`). A new text section starts with `Text.opening_body` when the body is blank. The content editor shows Body, with Update under it. Title and Subtitle live on the shared heading editor. On the public kit and the owner preview the heading is bold (`text-[2rem]`, `--surface-content-color`). The right-hand slot (`data-presskits-text-copy-slot`) renders `FlatPack::CopyButton` (`style: :secondary`, `size: :sm`, label **Copy text**, icon `clipboard-document`). It copies `Text.clipboard_text`: the full plain body, including lines hidden by **Show more**, with a blank line between paragraphs. The kit editor does not show that button. The body uses the theme muted text token (`--surface-muted-content-color`), `text-base`, `leading-7`, and `max-w-[65ch]`. It does not use the editor's `.ProseMirror` styles. Copy longer than 700 characters clamps to eight lines with a **Show more** / **Show less** `FlatPack::Button` (`style: :default`). Shorter copy has no toggle. The kit editor always shows the full body and edits it in place with `mode: :rich` (the bubble toolbar). Trashable is on the text recording and on the kit section. Orderable stays on the kit for kit sections. Publishable stays off both. FlatPack's engine importmap pins TipTap, including the content preset, and pins `flat_pack/clipboard` plus `flat_pack/copy` for **Copy text**. A host that skips that importmap has to pin those packages itself.

`RecordingStudioPresskits::Images` stores no heading of its own. It holds Attachable image files directly. Enable `Attachable.to` (`image/*`, up to 50 files) and `Orderable.to(allows: ["RecordingStudioAttachable::Attachment"])` on Images. Caption, credit, and alt live on each attachment. There is no width or height column. `ImagePixelSize` reads JPEG and PNG pixel size into the blob metadata when ActiveStorage's analyzer did not. The public kit and the editor preview resolve with `DirectImages` (direct images in Orderable order) and skip a trashed or missing photo, and skip a photo that still has no pixel size. The same helper paints the kit cover. The gallery is `FlatPack::Masonry::Component` (`columns: { base: 1, md: 2, lg: 4 }`, `gap: :lg`, `order: :columns`). Each cell is `with_item` and `FlatPack::Media::Component`, so each photo keeps its natural ratio. `JPG · width×height · ratio` is a `FlatPack::Badge` (`size: :xs`) in `with_item(placement: :bottom_left, inset: :sm)` on that media. The first 12 show. **Show more images (N)** is a Flatpack button, `style: :default`, inside the gallery's Turbo frame. N is the count of photos in the section. The link is the same page with `images` set to the images recording id, so Turbo replaces that frame with the rest. No extra JavaScript. On the public section card, the heading is `FlatPack::SectionTitle` with a `FlatPack::Badge` (`size: :sm`) in `with_trailing`. The badge text is the photo count. It sits after the title and outside the copy-link anchor. The editor heading stays `FlatPack::InlineEdit` and does not show that badge, because `SectionTitle` `title:` is a string and Inline Edit has no trailing slot. **Download all images** sits on the heading row, a Flatpack button, `style: :default`, icon `arrow-down-tray`. It downloads a zip of that section's photos only, from `ImageArchivesController`, and only when `Visibility.presentation_for` is `:full`. The kit zip is unchanged: cover, then every images section, plus `kit.txt`. **Upload** is Attachable's file button (`attachment_file_buttons/button`), the same partial as the kit cover. It stays on the import form so each click adds a photo. Attachable's own button would switch to **Change** and replace the first file. The button accepts one file at a time and uses direct upload. Attachable's collection editor (`association: :images`, list / slides / grid) reorders with `recording_studio_orderable_reorder!`. **Trash** removes that attachment. Editing caption, credit, or alt revises that attachment only. Quote still attaches one image directly. Title, Subtitle, and Update sit on the shared heading editor. The subtitle is the credit line under the heading. An empty images section shows an Add placeholder in the kit editor and stays off the public kit. The line under the photo is the attachment name. Media does not take a caption, so that name is the text in the same masonry cell.

Quotes use two recordings under the kit section. `RecordingStudioPresskits::QuoteSection` orders its quotes and stores no heading. Each `RecordingStudioPresskits::Quote` has `body`, `name`, and optional `role` and `organisation`. The UI creates a quotes section with the title Quotes. `create_section!` still takes an optional title. The preview and the public page show Quotes until someone saves a different title. A kit migrated from 0.16 copies the heading Quotes onto the kit section, because that is the heading the public page showed before. The section page uses the shared section editor. **+ Quote** and the quote list sit on the Content tab in column one. Title, Subtitle, and Update sit on Section title, with Update under those fields. + Quote is a primary button with a Heroicons plus icon and the label Quote. Column two, the kit preview, and the public page render each saved quote with `FlatPack::Quote::Component` at `size: :lg`. The citation is the name, role, and organisation. The row shows the quote, truncated to the column, with the name underneath. A blank quote uses Quote on the first line. A blank name leaves the second line off. + Quote opens that quote's edit screen. Orderable is on the quote section for its quotes. Attachable is on Quote for one image, and the upload stays on the quote screen. Publishable stays off the quote section and the quote. A blank body is left off the preview and the public page. Quote stays off the + Section menu because its parent is the quote section.

Facts & Figures use two recordings under the kit section. `RecordingStudioPresskits::FactsSection` orders its facts and stores `display_style` (`list`, `cards`, or `table`, default list) and `columns` (`2`, `3`, or `4`, default 3). Columns apply to cards only. Each `RecordingStudioPresskits::Fact` has a required `label` and `value`, plus optional `unit`, `description`, `source_url`, and `as_of_date`. Value stays text. A source URL, when present, must be HTTP or HTTPS. A kit can hold more than one facts section, each with its own heading and layout. The UI creates a facts section with the title Facts & Figures. `create_section!` still takes an optional title. The preview and the public page show Facts & Figures until someone saves a different title. The section page uses the shared section editor. **+ Fact**, Show as, Columns, and the fact list sit on the Content tab. Title, Subtitle, and Update sit on Section title. + Fact is a primary link with a Heroicons plus icon and the label Fact. It opens a new fact screen. Label, value, and unit are the primary fields. Description, source, and as of sit under More detail. Orderable is on the facts section for its facts. Publishable stays off the facts section and the fact. An empty facts section does not leave a blank preview card. List shows label and value pairs. Cards put the value first, then the label, in the saved column count on larger screens. Table is two columns, Fact and Value. The unit joins the value with a single space, or stays off when it is blank.

Credits are reusable, and the role in a kit is not. `RecordingStudioPresskits::Credit` is a child of the workspace root, next to press kits. It stores `name`, an optional `url`, and an optional `usual_role`. People manage those on **Credits**, linked from Library in the press kit index sidebar. Create and edit go through `RecordingStudioPresskits::Credits`. Trash uses `recording_studio_trashable_trash!`. Restore uses `recording_studio_trashable_restore!`, including from Trashable's trash bin for the workspace. A trashed credit stays out of search and off the public page. Lines that already point at it stay in the section, so restoring the credit puts it back.

A credits section is `RecordingStudioPresskits::CreditsSection` under a kit section, registered with `register_section`. The menu label is Credits and the icon is `user-group`. The kit section still holds the title and subtitle. The section orders `RecordingStudioPresskits::CreditLine` children. A line stores `role`, an optional `icon`, and `credit_recording_id`. It does not copy the name or URL. `icon` is a string column on `recording_studio_credit_lines`. The editor picks it from `CreditIcons`, a short curated list of Flatpack icon names. A blank or unknown name is stored as nil. Nothing guesses an icon from the role. `Credits.add!` copies `usual_role` into `role` only when the new line has no role of its own. Editing the credit's usual role does not revise existing lines. The same credit can appear in several kits, and more than once in one section, each line with its own role and position. Removing a line trashes that line only. `CreditsSection::Component#render?` is false when no visible line remains, so an empty credits section does not leave a blank preview card.

The credits editor returns true from `below?`. Title, Subtitle, and Update stay on the shared heading editor. In the content editor, the collection editor is its own form. **Save** sits under that table, only as wide as its label. The form uses Flatpack's unsaved-changes controller, and Save is `style: :default` with the submit target. It stays default while the rows match the saved lines and turns primary when they do not. Putting the rows back returns it to default. The editor has no extra heading. **+ Credit** adds a row. The first column searches workspace credits and stores `credit_recording_id`. The search reads `Credits.active_for_root` and matches the name and usual role. No match offers **+ New**, which opens a modal for the name, default role, and URL. The modal label is Default role. The stored field stays `usual_role`. Creating one saves the workspace credit and selects it on the row. The chip shows the name. The second column is **Role on this kit**, a free-text cell on the line. The third column is **Icon**, a select of that curated list, including **No icon**. Save walks the rows and calls `Credits.remove!`, `Credits.revise_line!`, and `Credits.add!`. `Credits.revise_role!` still revises the role and keeps the line's icon. A blank role on a new line still copies `usual_role` inside `Credits.add!`. An existing line updates its role and icon. A save that omits `icon` keeps the stored icon. A blank icon clears it. Removing a row trashes that line. The credit stays in the workspace. The same credit can sit on two rows. A trashed credit already on a row shows **In the trash**. The preview column follows the rows before Save. Choosing a credit adds that line. A blank role on a new row shows the usual role, which is what Save stores. Typing **Role on this kit** updates the role. Removing a row takes that line out of the preview. Dragging a saved row sends `moving_recording_id` and a 1-based `target_position` and expects `{ ok: true }`, and the preview follows that order. Column two on the kit editor, the kit preview, and the public page show the lines in a `FlatPack::Grid` (`cols: 4`: one column on a phone, two from `md`, four from `lg`). Each line is a small uppercase role, then the name in bold. When any visible line has an icon, every line reserves an icon-sized space: a `FlatPack::Avatar` (`size: :sm`, `shape: :circle`, decorative) for a chosen icon, or an empty spacer so the names line up. When no line has an icon, that space stays off. A URL on the credit makes the name a link with an `arrow-up-right` icon. The public section card keeps the section heading and puts **Copy credits** (`FlatPack::CopyButton`, `style: :default`, `size: :sm`) on the right of that heading. The clipboard text is `Role: Name`, one credit per line. A blank role copies the name alone. The kit editor heading stays the inline title and does not add that button. A trashed credit is omitted there. Publishable stays off the credit, the line, and the credits section.

A video section is the same shape. Press Kits owns `RecordingStudioPresskits::VideoSection`, an empty recording under the kit section. Recording Studio Video owns each `RecordingStudioVideo::Video` child. External Embed owns the provider embed. YouTube ships with External Embed. Another provider, including Vimeo, appears when the host registers it. Press Kits does not register Vimeo, and it does not call `RecordingStudio::ExternalEmbed.register`. The section includes Trashable, Videos, and Orderable for its videos. Drag a row on the content editor to choose which clip is first. The public card for that first video is full width. The rest sit in a two-column `FlatPack::Grid`. One video is only the featured card. A leftover in the grid sits in the first column. Title and subtitle stay on the kit section. + Video sits in the content editor and links to a new video. That screen uses Video's field helper for the title, URL, and description, then Press Kits fields for length (`m:ss`, stored as `duration_seconds`) and an optional thumbnail URL. A blank thumbnail uses YouTube's `i.ytimg.com` `hqdefault` image, or Vimeo's oEmbed thumbnail. The public card does not show the description. It shows a `FlatPack::VideoPreview` (poster, centred play control, the provider player held in a template until play), the title, a muted provider and length line, and **Copy link**. Below `sm` that button is the link icon only. Its accessible name and tooltip are **Copy link**. From `sm` up the words show, and the title wraps beside the button. The public heading puts a small muted count pill in `SectionTitle`'s trailing slot, after the title and outside the copy-link anchor. The editor heading does not show that count. Copy link uses the clipboard and Flatpack's `toast:add` event. Removing a video trashes that recording. Removing the section trashes the kit section and the videos under it. Neither path deletes rows.

A Location section is the same shape for places. Press Kits owns `RecordingStudioPresskits::LocationSection`, an empty recording under the kit section. Recording Studio Location owns each `RecordingStudio::Location::Location` child. The section includes Trashable and `RecordingStudio::Capabilities::Location.to`. It does not include Orderable, so places stay in the order they were added. Title and subtitle stay on the kit section. This is not the kit-header place: `KitLocation` still looks up the one optional Location child of the press kit. A Location section can hold one or more places. + Location sits in the content editor and links to a new place. That screen uses `recording_studio_location_search_fields` (place search, Add address manually, title, type, and icon when `icon_mode` is `:choose`). Preview and the public page render `recording_studio_location_display`. Removing a place trashes that recording. Removing the section trashes the kit section and the places under it. Neither path deletes rows. Press Kits does not copy Location's table or picker.

The kit list row label is the content type, such as Images, Quotes, Facts & Figures, Credits, Video, or Location. A text section with a saved title uses that title. A blank text title stays Text. The label truncates to the column. A saved text title is also the link title, so the full name stays available. The kit section title is the heading on the preview and the public page. When that title is blank, the heading is the content type label. The Title field stays empty and uses that label as its placeholder. A saved title replaces the fallback. The fallback is not enough to show the preview card. The page nav title uses the same heading. The heading on the section editor page is the content type label.

A content editor is a ViewComponent. `initialize` takes the content recording as `recording` and the form path as `update_path`. The class defines `param_key` and `permitted_attributes`. It does not build the page. `SectionEditorComponent` wraps that editor in the content modal. Title and Subtitle stay on `SectionHeadingEditorComponent`. Both forms use Flatpack's unsaved-changes controller. Update is `style: :default` and the submit target. Define `self.below?` and return true when the editor has its own screen controls and cannot share a form. Those editors render `section_actions`, then the editor. An editor that leaves `below?` unset renders inside its own form, with Update under its fields. Text leaves `below?` unset, so Body and its Update sit in the content editor. Images, Quotes, Facts, Credits, Video, and Location return true from `below?`. Text uses `RecordingStudioPresskits::Text::EditComponent`, `param_key` `:text`, and permitted attribute `:body`. Images uses `RecordingStudioPresskits::Images::EditComponent`, `param_key` `:images`, and no permitted attributes. Quotes uses `RecordingStudioPresskits::QuoteSection::EditComponent`, `param_key` `:quote_section`, and `below?` true. Facts uses `RecordingStudioPresskits::FactsSection::EditComponent`, `param_key` `:facts_section`, permitted attributes `display_style` and `columns`, and `below?` true. Credits uses `RecordingStudioPresskits::CreditsSection::EditComponent`, `param_key` `:credits_section`, and `below?` true. Video uses `RecordingStudioPresskits::VideoSection::EditComponent`, `param_key` `:video_section`, permitted attributes empty, and `below?` true. + Video is a link, not a create that records a blank video. Location uses `RecordingStudioPresskits::LocationSection::EditComponent`, `param_key` `:location_section`, permitted attributes empty, and `below?` true. + Location is a link, not a create that records a blank place.

When Recording Studio API is loaded, a press kit exposes show and update. Its payload keys are `title`, `description`, `brand_color`, and `font_family`. Title, description, brand colour, and font are writable. MCP uses the same payload. A missing brand colour or font reads as nil, which means inherit. The press kit also exposes `create_section` and `reorder_sections`. `create_section` takes `content_type`, `title`, and `subtitle` and calls `create_section!`. `reorder_sections` takes `ordered_recording_ids` and calls `recording_studio_orderable_reorder!`. A kit section exposes index, show, and update. Its payload keys are `title`, `subtitle`, `content_type`, and `content_id` for every section. `:videos` is declared on that type as well. The `videos` array is present only when the content is a video section. Each entry has `title`, `url`, `description`, `provider`, `canonical_url`, `content_type`, `duration_seconds`, and `thumbnail_url`. `thumbnail_url` is the picture the public card uses: the saved override, or the provider image when that override is blank. `duration_seconds` is null until someone saves a length. A video section's own show payload is that `videos` array. `:locations` is declared on that type as well. The `locations` array is present only when the content is a Location section. Each entry is Location's `api_payload` (the place fields plus `resolved_icon`, `display_name`, `full_address`, and `coordinates`). A Location section's own show payload is that `locations` array. Press Kits does not register `RecordingStudio::Location::Location` with the API. Location already owns that type. `:display` and `:facts` are declared on the kit section as well. Those keys are present only when the content is a facts section. `display` is `{ style, columns }`. Each fact has `label`, `value`, `unit`, `description`, `source_url`, and `as_of_date`. Optional fields are `null` when blank. Facts stay in Orderable order. Trashed facts stay out. A facts section's own show payload is that `display` object and `facts` array. MCP reads the same structured data through this payload. There is no separate facts API framework. Press Kits does not register `RecordingStudioVideo::Video` with the API. Video already does, including the derived provider fields. The kit section also exposes `remove_section`, which trashes the kit section. Trashable then trashes the content under it. There is no generic kit section create, because a kit section without content would break the one-content rule, and no kit section destroy. Text exposes show and update for `body`. A credit exposes index, show, create, and update for `name`, `url`, and `usual_role`. It does not expose destroy. Trash the credit recording instead, so lines that point at it keep their `credit_recording_id`. A credit line exposes index, show, and update for `role` and `icon`. Show also returns `name`, `url`, and `credit_id` from the credit when that credit is still active, and `icon` from the line when one is set. `add_credit` on the credits section takes `credit_id`, an optional `role`, and an optional `icon`, and calls `Credits.add!`. `reorder_credits` takes the same order params as the line list. `remove_credit` on the line trashes that line and leaves the credit. The member actions are `POST .../press_kits/:id/actions/create_section`, `POST .../press_kits/:id/actions/reorder_sections`, `POST .../kit_sections/:id/actions/remove_section`, `POST .../credits_sections/:id/actions/add_credit`, `POST .../credits_sections/:id/actions/reorder_credits`, and `POST .../credit_lines/:id/actions/remove_credit`.

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

Who can see a live kit is a second axis from published vs draft. Presskits registers Accessible action `presskits.kit_view_full` (default audience `public`, granted roles `view` / `edit` / `admin`). The owner picks that audience on **Visibility** in the kit editor toolbar. Accessible stores the audience. Presskits stores only `visibility_fallback` (`preview` or `hidden`, default `preview`) on a sidecar `KitSetting` row keyed by the kit recording — not on the revisioned PressKit, so changing it does not `revise` the kit or fire Publishable `revised`. When the audience is not public, that fallback decides what everyone else sees.

Call `RecordingStudioPresskits::Visibility.presentation_for(actor:, kit:)` from every visitor path. It returns `:full`, `:preview`, `:hidden`, or `:unavailable`. Unpublished kits are unavailable to visitors; owners and editors keep draft preview and edit. Full access is Accessible `authorized_action?` for `presskits.kit_view_full`. Otherwise the kit's fallback applies. Hidden kits 404 without confirming they exist, stay off `KitQuery.discoverable_for(actor:)`, and must not leak metadata. Public show assigns `Current.actor` from `current_user` (including nil) so a leftover editor from an earlier request in the same process is not treated as the visitor. Publishable's `RendersPublicPage` calls `show` without filters, so that assignment lives in `show` as well as a `before_action`. Listings take an explicit `actor:`. Preview renders only an allowlist: title, subtitle, cover image, company name, kit location, and the default Press kit badge. The short description stays off the limited preview and off its meta tags. No date, no sections, no protected assets, no Download. Below that, a **See full press kit** section heading (the same `SectionHeadingComponent` as kit sections) introduces why the rest is limited. A signed-in audience says “You must be signed in to {site name} to view this press kit.” Site name is `config.site_name`, then the i18n key `recording_studio_presskits.visibility.site_name`, then the Rails application name. Sign in uses `config.sign_in_path` (default `/users/sign_in`). Create account uses `config.registration_path` and stays hidden when that is blank. Granted and custom audiences say “You need access to view this press kit.” and skip those buttons. Hosts can add registered custom audiences to the action's `allowed` list. If a workspace constraint removes the selected audience, Accessible falls back to `granted` and the editor shows the audience that is in force.

Non-full public responses set `Cache-Control: private, no-store`. A full response does too while an embargo is still active, so a journalist's page is not stored for everyone else. Fragment caches must include the presentation, and while an embargo is active they must also include `Visibility.fragment_cache_key` (the release time and the actor). This gem has no public HTTP API or MCP of its own. The optional Recording Studio API payload is for callers who already have recording access. While an embargo denies `presskits.kit_view_full`, those payloads drop the protected fields (description, section headings, quotes, facts, videos, credit lines, and places). Editors still receive them.

A visitor who cannot see the full kit does not get **Download kit**. Access requests, journalist verification, and a unified Locked/Unlocked access UI are later work.

Embargo is `recording_studio_embargo` 0.1.0. This repository vendors that tag at `vendor/gems/recording_studio_embargo` because the GitHub repo is private. Switch that Gemfile entry to the git source once CI can reach it. Press kits opt in with `RecordingStudio::Capabilities::Embargo.to` for `presskits.kit_view_full` and `presskits.kit_download`. Publishable still decides whether the kit is live. Accessible still decides the standing audience. An active embargo asks `RecordingStudioEmbargo.restriction_for`. `:deny` uses the kit's visibility fallback (`preview` or `hidden`) and blocks download generate, fetch, and status, including a zip that already exists. Early access is the gem's one switch. `:allow` means the actor already satisfies Accessible's `:granted` audience for that action. A view grant does not include download. `:not_applicable` (no embargo, disabled, or the release time has passed) leaves visibility and downloads as they were. Nothing has to run at the release time. The kit editor toolbar calls `render_embargo_button` after **Downloads**. That opens the gem editor at `/recording_studio_embargo/recordings/:id/embargo/edit`. Default copy is `recording_studio_embargo.editor` in the gem. Override `subtitle`, `enable_help`, and `early_access_help` in the host locale. The public preview adds an **Embargoed** badge and the release time, drops the cover image, and keeps the usual preview allowlist otherwise. Copying a kit clears the window.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index, the kit editor, the header screen, the section editor, and owner preview are ViewComponents you can reuse or replace.

- Index: the current root's live kits, inside `FlatPack::SidebarLayout::Component`. The heading is **My presskits**. **Presskit** with a Heroicons `plus` icon is first and left. Cards vs table is icon-only `FlatPack::ButtonGroup::Component` (`squares-2x2` / `table-cells`, aria labels only). Do not mint a Press kits toggle. This Flatpack pin's SegmentedButtons is text-only. The sidebar has a collapsible **Library** group (`FlatPack::Sidebar::Group::Component`, open at first). **Credits** (`user-group`) opens the workspace credit list. Images are not a library. On a narrow screen, **Open sidebar** shows that group. There is no Credits button beside Presskit. Each card is `Cover::Component` at `:card`. A narrow card stays stacked: cover photo or a muted surface, a default **Press kit** badge, company, title, subtitle, description, the kit location under that description, and **View**. That stacked card does not show a release date; the kit location stays on its own line under the description. From 640px of the card's own width the cover moves to the left half and the body stays on the right, and the date and the kit location share one wrapping line under the description. Each shows only when it is present. Cards and the table open the kit editor. The index does not add a second full-width copy of a kit.
- Empty index: what happened, and a way to make a kit.
- Credits: people, companies, and organisations for this workspace. The subtitle is "People, companies and organisations that you credit in Press kits". **+ Credit** is only as wide as its label. The table shows the name. Edit keeps Name, Usual role, and URL. **Save** sits under those fields and is only as wide as its label. **Trash** shares that line, sits on the right, and uses the danger style.
- Kit URL: `GET press_kits/:id` requires edit access and redirects to the kit editor.
- Kit editor. The page is the live kit, full width. The kit header is the same `Cover::Component` at `:card` as the index, with no `href`. Across the full width of the preview it uses the horizontal layout. Each section below is its own Flatpack card. A slim toolbar holds **Section** (Heroicons `plus`, primary), **Order**, **Visibility** (Heroicons `eye`, default, kit owners and editors), **Downloads** (Heroicons `arrow-down-tray`, default), **Embargo** (`render_embargo_button` from the embargo gem: "+ Embargo" until a hold is active, then warning **Embargoed** with a lock), and `render_publishable_quick_actions`. **Visibility** and **Downloads** sit on the same row as publish. **Section** opens a modal list of registered content types and adds at the end, or into an empty kit. Each row has the type on the first line (Text, Images, Quotes, Facts & Figures, Credits, Video, Location) and a short line on why that block helps a press kit. Text uses `document-text`, Images uses `photo`, Quotes uses `chat-bubble-bottom-center-text`, Facts & Figures uses `calculator`, Credits uses `user-group`, Video uses `video-camera`, and Location uses `map-pin`. A host content type defines `self.section_menu_icon` to supply its own. Choosing one calls `create_section!` with that type's label as the title, then stays on the kit. Orderable places it after the current section or at the end. The new section scrolls into view and highlights. A Flatpack toast offers **Undo**, which trashes it. There is no title form and no **Save** on this page. Sections below the header lay out like the public kit. On a pointer that can hover, hover or focus-within tints a region with `--surface-muted-background-color`. Keyboard focus uses `:focus-visible` only. On touch (`@media (hover: none)`), a tap makes the header the active region so its wash shows. Tapping another region moves that active state. Tapping outside clears it. Flatpack has no tap-to-activate or hover-only visibility API, so a small Stimulus controller (`recording-studio-presskits--editor-chrome`) owns the header's touch active state. The header card and each section card are separate. `gap-6` sits between them. A section card is `SectionCardComponent`: Flatpack `Card` at `padding: :none`, white, `rounded-[var(--radius-lg)]`, and the same soft shadow as the header. The pad inside a section stays `pt-8 pb-8 px-8`, then `md:pt-10`, then `lg:pt-12` (`p-8 md:p-10 lg:p-12`). Phone padding stays `p-8`. `gap-6` is the space between the header card and each section card. The pad stays inside the card. The kit header has no FAB. Hover shows **Edit**, the same `FlatPack::Button::Component` (`size: :sm`) as a section's **Edit**. On a wide card it is a body overlay item (`placement: :top_right`, `inset: :lg`) and does not reserve space beside the heart. On a narrow card it sits on the cover overlay, immediately left of **Edit image**. It opens kit location and **Brand** in `pk-editor`. **Edit image** is an overlay item at the top right of the cover, opposite the **Press kit** badge, and opens **Cover image**. Header hover and tap use an inset overlay (`color-mix` black at 16%) instead of a surrounding muted tint, so the colour still bleeds to the card. A section has no FAB and no per-section add. Section actions are a small row: **Edit** (the content screen in `pk-editor` for images, credits, quotes, facts, video, and location — not the title or subtitle), **Order** (the existing Reorder modal, fragment on this section), and an icon-only `FlatPack::TrashButton::Component` (`size: :sm`, `expand: :left`, `method: :delete`). A text section has no **Edit**, so the row is **Order** then trash. Trash uses that button's confirm animation. There is no extra confirm dialog. The trash control uses the same `:sm` size as **Edit** and **Order**. Its hit-target floor is cleared so the box matches those labeled buttons. Hover or focus shows the row on a pointer that can hover. The section itself does not take a hover background. Below the `sm` breakpoint, and on touch (`@media (hover: none)`), the row stays visible. Below `sm` that row sits above the title, at the top-right corner of the section. **Edit** and **Order** show only their icons there (`max-sm:[&>span]:sr-only` plus `aria-label`). The boxes stay the labeled `:sm` size. From `sm` up those buttons stay labeled and sit beside the title. Title and subtitle are `FlatPack::InlineEdit::Component` (`mode: :text`, `cue: :highlight`). Hover shows the text is editable. Click edits in place. An empty subtitle shows **Add a subtitle** and stays clickable. Saves PATCH `kit_section[title]` or `kit_section[subtitle]` on the section update path. A save that sends only one of those leaves the other. A blank stored title still shows the content type label. A text section hides **Edit**. Its body is `FlatPack::InlineEdit::Component` with `mode: :rich` (the bubble toolbar) and saves `text[body]` to that same section update path. The public kit and the owner preview use the same stack: the wide brand card, then one card per section. Sections other than text use `SectionTitle` and its anchor. A text section uses a bold heading and an empty copy slot, then the themed body. The limited preview puts its explanation in that section card under the header. Download stays on the header card. On that card the title, subtitle, and short description edit in place. **Edit** opens the header screen. **Edit image** opens that screen at `#press_kit_cover_image`. Those editors open one navigable `FlatPack::Modal::Component` (`id: "pk-editor"`, `navigable: true`, `size: :lg`). The first screen loads from `src` into turbo frame `pk-editor-screen`. Heading, content, and child screens (`facts`, quotes, videos, credits, locations) wrap in `flat_pack_modal_screen`. Drill-down links and create forms use `data-fp-nav="push"`. Back re-fetches the previous screen. Do not nest modals, and do not add a custom stack or unsaved-close guard — Flatpack has not shipped save-complete or unsaved protection yet. Empty sections show an Add placeholder in the editor. Public kits skip sections with nothing to show. **Order** opens **Reorder**, a separate modal with the Orderable list (`orderable: true`, `divider: true`, `orderable_url` posting `moving_recording_id` and a 1-based `target_position`). That route calls `recording_studio_orderable_move!`. Each row is a kit section. The link opens content. The link text is the content type, such as **Images**, **Quotes**, or **Facts & Figures**. A text section with a saved title uses that title. A blank text title stays **Text**. The label uses `truncate`. Remove is an icon-only trash button. Saves refresh the changed section behind the modal with Turbo streams and stay on the current screen. Those save forms use `data-turbo-frame="_top"` so the navigable screen frame does not swallow the stream. Types come from `picker_types`. **+ Access** stays on this page.
- Visibility. **Visibility** on the kit editor toolbar (same row as publish) opens a `pk-editor` screen with one heading: PageTitle **Visibility**, subtitle **Who can view this press kit**. There is no small chrome title. It is not on the kit header. **Edit** there is location and brand. The form uses `max-w-xl` like other one-job editor screens, full width on a phone. **Who can view the full press kit?** stays for screen readers (`sr-only`) and is not shown. Audience is a Flatpack RadioGroup (`variant: :inline`) of Accessible `audience_options_for` after host and workspace constraints, with the same icons as Downloads: Anyone `globe-alt`, Signed in `user`, People with access `lock-closed`, custom audiences `user-group`. Default is Anyone. When that is not Anyone, **What should other visitors see?** is a Flatpack RadioGroup (`variant: :inline`) with icons: Preview (`eye`) and Hidden (`eye-slash`), the same inline picker Location uses for type and icon. Switching back to Public hides the fallback control and keeps the stored fallback. There is no Locked/Unlocked switch. **Update** sits under the fields, with `mt-4` above that row so the button is not flush with the last field. Saving calls Accessible `set_audience!` and `KitSettings.save_fallback!`. Direct `GET` of the screen still works, with Back to kit.
- Header. On the kit editor the title, subtitle, and short description edit in place on the card with `FlatPack::InlineEdit::Component` (`mode: :text`). Hover shows the text is editable. Click edits it in place. An empty title shows **Add a title** and an empty save is blocked in place. An empty subtitle shows **Add a subtitle**. An empty short description shows **Add a short description** and stays clickable. Title is required. Short description is optional, 280 characters at most. Each save PATCHes one of `press_kit[title]`, `press_kit[subtitle]`, or `press_kit[description]` on the header update path. A save that sends only one leaves the others, and leaves the release date, brand, and location. Index cards, the public kit, and the owner preview keep the static words. **Edit** on the card opens kit location, **Release date**, and **Brand** in `pk-editor`. **Edit image**, on the cover, opens **Cover image**. That upload and remove stay outside the header save form. **Upload** becomes **Change** once a photo is attached. **Remove** trashes that attachment. When press centers is loaded, Brand is `FlatPack::Tabs` (`variant: :pills`): **Press center** and **Custom**. **Press center** stores both fields as nil and shows the font and colour that would be used. **Custom** shows `FlatPack::FontSwatch` (`size: :lg`) and `FlatPack::ColorSwatch` (`size: :lg`) on one line, prefilled with those resolved values, and saving stores both. An explicit `sans` or `#333333` is kept. Without press centers, the tabs stay off and the swatches show on their own. The header form does not preview the card. Update starts in the default style and turns primary when the form changes. Saving uses `revise` and refreshes the kit header with Turbo streams. Direct `GET` of the header screen still works, with Back to kit. **+ Access** stays off.
- Heading editor. `GET sections/:id/heading` is one shared form for every section type. The modal title is **Section heading**. Title, Subtitle, then **Update**. There is no Heading group. Update starts in the default style and turns primary when Title or Subtitle no longer matches the saved value. `SectionHeadingComponent` renders those fields on the public kit and the owner preview through Flatpack `SectionTitle`, except a text section, which uses `TextSectionHeadingComponent`. The kit editor uses inline edit for the same words (`size:`, `spacing:`, `level:`). A text section's editor title is the bold public heading. Other sections stay semibold. A blank title uses `section_heading`, which falls back to the content type label.
- Content editor. The content screen (or the direct section URL) holds that section's editor only. Quotes puts **+ Quote** there, then the quote list. A quote row or **+ Quote** pushes Edit quote. Facts puts Show as, Columns when the style is Cards, **+ Fact**, then the fact list. **+ Fact** and a fact row push the fact screen. Video puts **+ Video**, then the video list. Location puts **+ Location**, then the place list. **+ Location** and a place row push the Location search screen. Images puts Attachable's file button (**Upload**), then Attachable's image collection editor (list, slides, grid) for caption, credit, alt, drag reorder, and **Trash**. Credits puts a collection editor. **+ Credit** adds a row. **Save** under the table stores the lines. CollectionEditor's inline create still uses Flatpack's own create dialog. A direct visit still puts the FlatPack content editor there, labeled Body, with Update under it. On the kit editor the body is inline (`mode: :rich`) and **Edit** is hidden. There is no preview column on this screen. **+ Access** stays off.
- Owner preview: the same public page, on the default layout, for an authenticated owner. Back returns to the kit editor. A kit that is not live stays hidden from logged-out visitors.

Default-layout chrome is back, close, and page actions. **+ Access** is in the right slot on the kit editor only. Index, the new form, the header screen, the section editor, and owner preview leave that slot empty. Do not put Sign in, Sign out, or Root Switchable there. Core owns back and close.

Primary buttons: **Presskit** (Heroicons plus) on the index, **Create** on the new form, and **Section** on kit edit. Heading and header **Update** start in the default style and turn primary when that form changes. Content has one when the editor saves its own fields there, such as Body. Credits **Save** does the same under the credit table. Publish state stays on Publishable's own action. Do not hand-roll a second publish system.

## Public

A live kit is readable without signing in. Publishable serves `/published/:uuid/:slug` (override the path only if it still includes `:uuid`). `.to` sets `public_layout: "recording_studio_presskits/blank"`. That layout is a document and the kit: no back, no close, and no TopNav. The page title is the kit name. The kit opens as the same stack of cards as the editor. The header is the wide `Cover::Component` at `:card` in its own card (`overflow-hidden`): cover photo or muted frame, the default Press kit badge, company, location, title, subtitle, short description, and, under that description, the date and kit location on one wrapping line when either is present. Each section is its own card. When the visitor may download the kit, **Download kit** sits under the header through Downloadable's `recording_studio_downloadable_button` (preparing / ready / retry). The default public audience shows that button to logged-out visitors on a live kit. Flatpack has no download-control component at this pin, so Presskits does not invent one. The button is never on owner preview or the editor preview. A visitor who cannot see the full kit, or who lacks the download audience, does not see it. View and the publish menu Preview both use the same public page without that button. Owner preview stays on `recording_studio/default_layout`.

Logged-out visitors get a 404 for a kit that is not currently published. An authenticated owner can still open the owner preview on the default layout. A live kit whose audience is not public still goes through `Visibility.presentation_for`. Preview shows the card (eyebrow, title, company, location, cover, short description) then **See full press kit** with an explanation. Hidden is a plain 404.

Use `PressKit.indexable` / `indexable?` for publish state. Use `KitQuery.discoverable_for(actor:)` for public lists, search, and discovery so hidden kits stay out for people who cannot view the full kit. Preview kits may show their preview card. Admin widgets still list live vs not-live work for staff.

## Displaying press kits in a host

A press center, or any other host page, renders kits with the components in this section. The mounted index, kit editor, and owner preview stay on the engine. Those screens call `authenticate_presskits_actor!`, use the current root from Root Switchable, and render inside `recording_studio/default_layout`. The editor modal is Turbo frame `pk-editor`. Use the components below on a host page. Leave the engine routes for people editing kits.

In this section, **preview** means the audience preview: `Visibility.presentation_for` returns `:preview`, and the component is `RecordingStudioPresskits::PressKits::PreviewShowComponent`. **Owner preview** means `RecordingStudioPresskits::PressKits::PublicShowComponent` with `preview: true`, the authenticated page at engine `GET press_kits/:id/preview`.

### Requirements

Include `RecordingStudio::Capabilities::PressKits.to` on the recordable that should hold kits. `.to` takes no options and calls `RecordingStudio::Capabilities.include_for(:press_kits)`. The gem registers `:press_kits` at boot with `child_recordables: ["RecordingStudioPresskits::PressKit"]`. Core allows that recordable as a parent through `extra_capability_parent_types_for`. PressKit `allowed_parent_types` stays the host root. A capability-owned kit cannot sit under a shared root.

Register `PressKit`, `KitSection`, and each section content type the kits use. Section bodies resolve through `RecordingStudioPresskits.section_component_for` (the registered component, or `Type::Component`).

The host layout loads `tailwind`, `flat_pack/variables`, and `flat_pack/application`. The kit editor also needs `flat_pack/inline_edit` (title, subtitle, and text-body editing). Text sections also need `flat_pack/rich_text`. These components draw Flatpack. They do not ship a layout. The publishable page uses `recording_studio_presskits/blank`: a full HTML document, `data-theme="rounded"`, those stylesheets, and no page nav.

Publishable supplies the public URL and `currently_published?`. Accessible supplies `presskits.kit_view_full` for `Visibility.presentation_for`. Attachable supplies the cover photo and Images-section files. Without Attachable, the card frame stays a muted surface. Downloadable, and its view helper, supply **Download kit** inside `PublicShowComponent`. Companies (`allow: :one` on the root) and Location are optional rows on the card.

### `KitQuery.for_root`

```ruby
RecordingStudioPresskits::KitQuery.for_root(root_recording)
```

`root_recording` is the workspace (or other root) recording. A blank root returns `RecordingStudio::Recording.none`. Otherwise the query returns trashable-active `PressKit` recordings with that `root_recording`, including kits nested under another recordable. Order is `recording_studio_orderable_position`, `created_at`, `id`. The relation includes the recordable.

Live here means not trashed. Unpublished kits are included. Audience is not applied. The scope is the root, so every live kit in that root comes back, including kits that belong to a different parent in the same workspace.

### `Visibility.presentation_for`

```ruby
RecordingStudioPresskits::Visibility.presentation_for(actor:, kit:, purpose: :public)
```

`actor` is the visitor (`current_user` or `nil`). `kit` is a recording, or a recordable that responds to `recording`. `purpose` defaults to `:public`.

The return value is one of `:full`, `:preview`, `:hidden`, or `:unavailable`.

- `:unavailable` when the recording is missing, or the kit is not `currently_published?`. With `purpose: :editor`, an actor Accessible allows to `:view` the kit gets `:full` instead.
- `:full` when Accessible allows action `presskits.kit_view_full`.
- `:preview` or `:hidden` from the kit fallback (`KitSettings`) when the kit is live and the actor lacks that action.

On a host page, `:full` renders `PublicShowComponent`, `:preview` renders `PreviewShowComponent`, and `:hidden` and `:unavailable` render nothing. The publishable page does the same. `Visibility.apply_public_response!` sets `Cache-Control: private, no-store` for every presentation except `:full`, and sets status 404 for `:hidden` and `:unavailable`.

### Card

```erb
<%= render RecordingStudioPresskits::Cover::Component.new(
      recording: kit_recording,
      size: :card,
      href: kit_recording.publishable_public_path
    ) %>
```

```ruby
initialize(recording: nil, title: nil, description: nil, subtitle: nil, brand_color: nil, inline_path: nil,
           font_family: nil, size: :card, href: nil, id: nil, heading: :h2, add_to_list: true,
           show_image: true)
```

Every argument is optional. An unknown `size` becomes `:card`. `heading` is `:h1` on the kit page and `:h2` on a grid card. Title uses the argument, then the recordable title, then `"Press kit"`. Description and subtitle use the argument. Pass `description: nil` or `subtitle: nil` (the defaults) to read the recordable. `brand_color` and `font_family`, when passed, paint this card only. Otherwise the card uses `KitBranding` for the recording: kit value, then press center, then `#333333` and `sans`. **View** text uses `Cover::Contrast.text_on`. The Press kit badge does not.

`:card` is the grid card and the kit header. It is a Flatpack card with a soft shadow, not a link. The layout follows the card's own width (`@container`), not the viewport. Below 640px the top is the cover photo (`Cover::Image` through `CoverImage` and `DirectImages`, `object-cover`, rounded top corners, `aspect-[430/368]`) or a muted surface when the kit has no photo. The photo is `FlatPack::Overlay` media. A default **Press kit** badge (`style: :default`) sits at the top left, inset medium. On the editor card, **Edit image** is a second overlay item at the top right with the same inset. Flatpack paints that badge from the muted surface (`#e5e5e5`) and content text (`#333`) on the rounded theme, not from the brand. The body is a flex column. The company name from `Cover::Company` sits in small uppercase type 14px above the title (hidden when there is no company). The list heart is a body overlay item at the top right (`inset: :sm`), so the title, subtitle, description, and location use the full body width. The company line has `pr-16` so the name does not run under the heart. From 640px the heart uses `@min-[640px]:top-18` and lines up with that company line. The subtitle and the short description, clamped to three lines, follow the title. Once the card is at least 640px wide, the release date and the kit location share one wrapping muted line under the short description. Each shows only when it is present, and both blank hides the line. Below 640px the date stays off and location, when the kit has one, sits on its own line under the short description. A blank short description puts that stacked location under the title and subtitle. The limited preview leaves the short description off. The wide line still shows the date and the place. **View** is a rounded Flatpack button in a footer with `mt-auto`, so it sits on the bottom of the card. From 640px of container width the same pieces turn into a row: the cover is the left half, full height, and the body is the right half, with **View** still pinned to the bottom right when `href` is set. On that wide row the copy adds `@min-[640px]:pt-16` on top of the body's `pt-7`, so the company name starts about 6rem from the top of the card. A narrower public card does not get that extra padding. On a wide editor card, **Edit** is a Flatpack overlay item on the body (`placement: :top_right`, `inset: :lg`). It is out of the copy row, so the heart keeps the public card's right inset. Below 640px that copy is hidden, and **Edit** sits on the cover overlay immediately left of **Edit image** (`gap-2`). The editor copy has no extra top padding at that width, the same as the public card. The wide cover uses `rounded-tr-none` where it meets the body. The kit editor header is this card with no `href`, `heading: :h1`, and `inline_path` set to the header update path, so the title, subtitle, and short description are `FlatPack::InlineEdit::Component`. The editor description is not line-clamped. Other uses leave `inline_path` unset and keep the static text, with the short description clamped to three lines. The kit name stays the page heading and **View** stays off. Index cards keep `h2`. The same card is the header on the public page, owner preview, and audience preview. The card is `h-full` and fills its grid cell. The button background is the resolved brand colour and its label uses `Cover::Contrast.text_on`. `href` is that button's link. Sections stay off the card. Rebuild Tailwind so `@container`, the `@min-[640px]:` utilities, and the overlay placement utilities generate.

When `RecordingStudioLists::AddToListHelper` is loaded, the card has a recording, `add_to_list` is true, and `Current.actor` is present, the body overlay shows `recording_studio_add_to_list` with `icon: "heart"` and `size: :lg` at the top right. That control does not follow `href`. Without Lists, or without an actor, the card still renders and the heart stays off.

### Full kit

```erb
<%= render RecordingStudioPresskits::PressKits::PublicShowComponent.new(
      press_kit_recording: kit_recording
    ) %>
```

```ruby
initialize(press_kit_recording:, section_recordings: nil, preview: false, branding: true)
```

`press_kit_recording:` is required. `section_recordings:` defaults to `KitQuery.sections_for(press_kit_recording)`. `preview:` defaults to `false`. `branding:` defaults to `true`.

`branding: true` wraps the kit in `#presskits-kit-embed`. That is the kit embed a host drops on its own page. The style on that wrapper is `RecordingStudioPresskits.branding_style_for` (see **Press center branding**). `branding: false` skips the wrapper. The published page and owner preview pass `false`.

The component renders a stack: the wide header card (`Cover::Component` at `:card`, `heading: :h1`), then each visible section in its own card through `PressKits::SectionFrameComponent` (`section_recording:`). A section whose content component is missing, or whose `render?` is false, is skipped. When nothing remains, a section card shows the empty state **Nothing to show yet**.

`PublicShowComponent` does not call `Visibility.presentation_for`. It renders the recording you pass, sections included. Call `presentation_for` first and render this component only for `:full`.

With `preview: false`, **Download kit** renders when the kit is `currently_published?` and `KitDownload.allowed?` for `helpers.current_user` or `Current.actor`. The button is Downloadable's `recording_studio_downloadable_button`. The host controller includes that helper (`helper RecordingStudioDownloadable::Engine.helpers`, the same include `PublicPressKitsController` uses). A live kit on a controller without the helper raises when the button renders.

`preview: true` is owner preview. The download button stays off. A kit that is not `currently_published?` shows **This is just for you. Nobody else can see it yet.** The engine view `press_kits/preview` renders this inside `presskits_page_nav` on `recording_studio/default_layout`, after auth. That route is the owner page, not a fragment for a public host page.

### Audience preview

```erb
<%= render RecordingStudioPresskits::PressKits::PreviewShowComponent.new(
      press_kit_recording: kit_recording
    ) %>
```

```ruby
initialize(press_kit_recording:, reason: nil)
```

`press_kit_recording:` is required. `reason:` is optional. A blank reason uses `Visibility.preview_reason_for`, which returns `:signed_in` when the effective audience is `:signed_in`, and `:granted` otherwise.

The component renders the same card chrome and `Cover::Component` at `:card` (eyebrow, title, cover image, company, kit location). The short description stays off this card. Under the card, `SectionHeadingComponent` renders **See full press kit**, then the explanation. `:signed_in` says “You must be signed in to {site name} to view this press kit.” and shows **Sign in** (`Visibility.sign_in_path`) plus **Create account** when `Visibility.registration_path` is present. Any other reason says “You need access to view this press kit.” and shows no buttons. Sections and **Download kit** stay off.

### Publishable public URL

A live kit is served at `/published/:uuid/:slug` when Publishable is mounted at `/`. Override that path only if it still includes `:uuid`. The recording method is `publishable_public_path`. Inside a presskits engine view, `presskits_public_path_for(recording)` returns that path when the recording responds to it.

`PressKit` sets `public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`, and `public_layout: "recording_studio_presskits/blank"`. Publishable assigns `@parent_recording` and `@parent_recordable`. `PublicPressKitsController#show` sets `Current.actor` from `current_user` (including `nil`) and calls `presentation_for` with `purpose: :public`. `:full` renders `PublicShowComponent` with `preview: false` and the sections. `:preview` renders `PreviewShowComponent`. `:hidden` and `:unavailable` render no kit markup.

That response is a full document. There is no embeddable kit endpoint, and no engine route that returns the card or the kit as a fragment. Engine `press_kits` routes stay behind `authenticate_presskits_actor!`.

The published page wraps both the full kit and the audience preview in `#presskits-public-page`. The full kit inside that page is `PublicShowComponent` with `branding: false`, so the style is declared once.

### Press center branding

Press kits does not depend on press centers. `RecordingStudioPresskits.branding_style_for(kit_recording)` always returns a style string. `KitBranding` resolves `brand_color` and `font_family` independently: the kit value, then `RecordingStudioPressCenters.branding_for` when that constant is loaded, then `#333333` and `sans`. When `RecordingStudioPressCenters::Branding` is loaded, the string is `Branding.new(brand_color:, font_family:).style_attribute`. Otherwise `BrandStyle` emits the same tokens.

That string goes on a wrapper around the kit, never on `<html>`. The published page uses `#presskits-public-page` (full kit and audience preview). A host embed of `PublicShowComponent` uses `#presskits-kit-embed`. Owner preview uses `#presskits-owner-preview`. The kit editor puts the same string on `#presskits-editor-preview`, around the header card and the section cards. Audience preview also sets it on `#presskits-public-preview`.

The string sets `--color-primary`, `--color-primary-text` (auto contrast), `--color-primary-hover` and `--color-primary-active` (relative colour from the brand, the same lightness steps Flatpack uses), the primary button tokens, the ring tokens, and `font-family`. It has to sit on the wrapper. Flatpack resolves the button tokens and the ring tokens on the theme root, so changing only `--color-primary` on a parent does not repaint a primary button, and hover, focus, and the pressed fill stay on Flatpack's palette. The card also sets `font-family` on itself, so a kit font wins inside a press center wrapper. **View** uses the resolved colour directly. The **Press kit** badge is Flatpack's default style, so it stays on the muted surface and content text instead of the brand. Layouts that render a kit link `recording_studio_presskits/brand_buttons` so the pressed fill uses `--button-primary-active-background-color`.

Editor chrome stays on Flatpack's palette. The toolbar, page nav, header form, and tabs sit outside the preview wrapper. Section edit, order, and remove, the empty-section action, header **Edit**, and **Edit image** sit inside the preview, so they are wrapped with `presskits-neutral-controls`. That class restores `--color-primary` from Flatpack's brand knobs.

### Press center

`Center` stands in for the host recordable. It includes the capability, and it is not a shared root. Kits recorded under it use the center's root for `for_root`.

```ruby
class Center < ApplicationRecord
  recording_studio_recordable label: "Center",
                              root: false,
                              allowed_parent_types: ["Workspace"]

  include RecordingStudio::Capabilities::PressKits.to
end
```

The center page lists cards. `for_root` is every live kit in the workspace root, so other parents in that workspace appear in this grid until a parent-scoped query exists. Skip `:hidden` and `:unavailable` before rendering a card. `href` is the publishable path, which 404s for a kit that is not live.

```erb
<% kits = RecordingStudioPresskits::KitQuery.for_root(center_recording.root_recording) %>

<%= render FlatPack::Grid::Component.new(cols: 2, gap: :lg, align: :stretch) do %>
  <% kits.each do |kit| %>
    <% presentation = RecordingStudioPresskits::Visibility.presentation_for(
         actor: current_user,
         kit: kit
       ) %>
    <% next unless %i[full preview].include?(presentation) %>

    <%= render RecordingStudioPresskits::Cover::Component.new(
          recording: kit,
          size: :card,
          href: kit.publishable_public_path
        ) %>
  <% end %>
<% end %>
```

A center page that shows one kit branches on the same presentation. The controller that renders `PublicShowComponent` includes Downloadable's helper.

```erb
<% presentation = RecordingStudioPresskits::Visibility.presentation_for(
     actor: current_user,
     kit: kit_recording
   ) %>

<% if presentation == :full %>
  <%= render RecordingStudioPresskits::PressKits::PublicShowComponent.new(
        press_kit_recording: kit_recording
      ) %>
<% elsif presentation == :preview %>
  <%= render RecordingStudioPresskits::PressKits::PreviewShowComponent.new(
        press_kit_recording: kit_recording
      ) %>
<% end %>
```

### Planned

These are not in the gem. Do not call them.

- `presskit_card` helper. Renders `Cover::Component` at `:card` with the kit's public URL as `href`.
- A kit grid/list component. Cards for a set of kit recordings, plus an empty state. No index sidebar, no **My presskits** heading, no create button, and no credits link.
- A host-safe full-kit wrapper. Calls `Visibility.presentation_for` and renders `PublicShowComponent` for `:full`, `PreviewShowComponent` for `:preview`, and nothing for `:hidden` and `:unavailable`.
- `presskit_public_url(recording)`. A host helper for the publishable path. Today that path is `publishable_public_path` on the recording.
- `presskit_visible_to?(recording, actor)`. True when `presentation_for` is `:full` or `:preview`.
- A query for live kits under a given parent. `KitQuery.for_root` is scoped to the root recording.

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
| Recording Studio | `v4.5.0` |
| Accessible | `v0.15.0` |
| Admin | `v2.2.0` |
| Root Switchable | `v0.8.0` |
| FlatPack | `v0.1.235` |
| Attachable | `v0.15.0` |
| Company | `v0.4.0` |
| Location | `v0.6.0` |
| Orderable | `v0.3.0` |
| Trashable | `v0.8.0` |
| Duplicatable | `v0.5.0` |
| Publishable | `v0.8.0` |
| Downloadable | `v0.4.0` |
| External Embed | `v0.1.4` |
| Video | `v0.1.1` |
| Metrics | `v0.2.0` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.4 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, the kit editor, owner preview, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack `anchor_href` for the close X. The layout draws one back control. A screen that sets a back URL gets that link. A screen that does not gets PageNav's history button. Core still stores the close path in `page_nav_anchor_url` and the back path in `page_nav_back_url`. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, Publishable, Downloadable, Attachable, Company, Location, the vendored embargo gem, and this gem so that layout is not an unstyled box.

The public kit view uses `recording_studio_presskits/blank` instead. Do not use Publishable's empty TopNav there. Do not insert Sign in, Sign out, or Root Switchable into PageNav. Core owns back and close on the default layout. **+ Access** is in the slot on the kit editor only. Cards, table, the kit editor, the header screen, public show, owner preview, and Admin live in `docs/dummy-screenshots/`. After seed: `press-kit-index-cards.png`, `press-kit-index-table.png`, `workspace-kit-edit.png`, `workspace-kit-edit-mobile.png`, `workspace-heading-edit.png`, `workspace-content-edit.png`, `workspace-fact-drilldown.png`, `workspace-header-edit.png`, `workspace-kit-show.png`, `public-press-kit-show.png` and `public-press-kit-show-mobile.png` (logged-out Spring launch), `public-kit-download-desktop.png` / `public-kit-download-mobile.png` (logged-out **Download kit** on the public page), `workspace-kit-downloads.png` (Downloads setting in `pk-editor`), `hero-restyle-editor-desktop.png` / `hero-restyle-public-desktop.png` plus mobile and crop companions, `hero-company-editor-desktop.png` / `hero-company-public-desktop.png` plus mobile and crop companions (company + kit location on the colour header), `hero-cover-image-editor-desktop.png` / `hero-cover-image-public-desktop.png` plus mobile and crop companions, `hero-cover-colour-editor-desktop.png` / `hero-cover-colour-public-desktop.png` plus mobile and crop companions, `hero-cover-grid-desktop.png` / `hero-cover-grid-mobile.png`, `owner-preview-unpublished.png` (owner preview of Autumn recap), and `admin-press-kits.png` (live vs not-live). Do not recapture dummy home.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one published kit titled **Spring launch**, with a short description, a sky cover (`#BFDBFE`, Auto dark text), a Harbour Gallery cover photo attached on the kit, **Harbour Studio** as the workspace company, **Harbour Gallery** as the kit location, credits, company statistics as cards, and project specifications as a list, and one unpublished kit titled **Autumn recap**. Dummy Workspace enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. It also enables `Companies.to(allow: :one)`. Dummy `Showcase` includes `RecordingStudio::Capabilities::PressKits.to` so a kit can sit under a showcase as well as the workspace. It is a test recordable, not a screen. Dummy `FakeBlock` stays test-only. Its parent is a kit section. It enables Trashable so remove is testable, it is excluded from the add dropdown, and it does not enable Publishable. Its `prepare` hook sets the block title from the create heading, or to Block when that heading is blank. The seeded admin user gets Accessible owner access on the workspace and the admin root.

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
