# Recording Studio Press Kits

A press kit holds ordered sections. Each section is a `RecordingStudioPresskits::KitSection` recording. The child under that recording is the content, such as text, images, or quotes. A later addon registers its own content type under a kit section.

Kits sit under your workspace. You can have many. You publish the kit, not each block. This gem ships the authenticated editor, a public page for a live kit, an owner preview of a kit that is not live yet, and Admin widgets for live vs not-live work.

## Install

Add the gem next to Recording Studio 4.4, Accessible 0.14, Admin 2.0, Publishable 0.7, Company 0.3, Location 0.4, and the mixins PressKit already opts into. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.4.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.14.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.1.0"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.7"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.6.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.5"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.7.0"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.13.0"
gem "recording_studio_company", github: "bowerbird-app/RecordingStudio_company", tag: "v0.3.0"
gem "recording_studio_location", github: "bowerbird-app/RecordingStudio_location", tag: "v0.5.1"
gem "recording_studio_external_embed", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.4"
gem "recording_studio_video", github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.1"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.224"
gem "recording_studio_presskits", github: "bowerbird-app/RecordingStudio_presskits"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.14"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_orderable", "~> 0.2"
gem "recording_studio_trashable", "~> 0.6"
gem "recording_studio_duplicatable", "~> 0.4"
gem "recording_studio_publishable", "~> 0.7"
gem "recording_studio_attachable", "~> 0.13"
gem "recording_studio_company", "~> 0.3"
gem "recording_studio_location", "~> 0.4"
gem "recording_studio_external_embed", "~> 0.1.1"
gem "recording_studio_video", "~> 0.1.0"
gem "recording_studio_metrics", "~> 0.2"
gem "flat_pack", ">= 0.1.224"
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
bin/rails generate recording_studio_attachable:install
bin/rails generate recording_studio_attachable:migrations
bin/rails generate recording_studio_company:install
bin/rails generate recording_studio_company:migrations
bin/rails generate recording_studio_location:install
bin/rails generate recording_studio_location:migrations
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
    "RecordingStudioPresskits::FactsSection",
    "RecordingStudioPresskits::Fact",
    "RecordingStudioPresskits::VideoSection",
    "RecordingStudioVideo::Video",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudioCompany::Company",
    "RecordingStudio::Location::Location"
  ]
  config.require_recordable_declarations = true
end

RecordingStudioPresskits.configure do |config|
  config.parent_root_type = "Workspace"
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
  config.cover_colors = %w[#1F2937 #BFDBFE #DB2777 #059669 #D97706]
  config.default_cover_color = "#1F2937"
  config.cover_text_colors = %w[#F8FAFC #111827 #E5E7EB #6B7280]
  config.cover_text_auto = true
end
```

The kit declares itself as a nested type under that root, then opts into Orderable, Trashable, Duplicatable, Publishable, Location, and LibraryPlacement with the current `.to` API only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path for these mixins. Do not enable Publishable on section children. Company and the image library are host opt-ins on the root, not on the kit. PressKit also enables Accessible `:action_audiences` so a kit can hold an `AccessRule` for who may view the full kit. Enable `:action_audiences` on the host root too if the workspace should be able to narrow those audiences.

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
include RecordingStudio::Capabilities::Location.to
include RecordingStudio::Capabilities::LibraryPlacement.to

RecordingStudio.enable_capability(:action_audiences, on: self)
```

On the host root, turn companies on when you want the hero company row, and the image library on when kits should pick a cover photo. Dummy Workspace uses one company per root:

```ruby
include RecordingStudio::Capabilities::Companies.to(allow: :one)
include RecordingStudio::Capabilities::ImageLibrary.to
RecordingStudio.enable_capability(:action_audiences, on: self)
```

Orderable on the kit allows `RecordingStudioPresskits::KitSection` and `RecordingStudioAttachable::Placement`. KitQuery and the Reorder screen still list only kit sections. A cover placement stays on the kit when sections move. Position is a column on those recordings. Reorder history is an event on the kit. A quote section orders its own quotes. Content recordings are not ordered as kit children.

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
  kit.cover_style = "color"
  kit.cover_color = "#BFDBFE"
end

kit_recording.log_event!(action: "noted")
```

The header is the press kit. `title` is required. `description` is an optional short line, 280 characters at most, and a blank one is stored as nothing. The cover is also on the kit: `cover_style` is `color` for now (`nil` means colour with the default), `cover_color` is a hex string, and `cover_text_color` is an optional hex for the title and description. A blank colour uses `default_cover_color` (`#1F2937`). A blank text colour uses Auto: light or dark, whichever has the better WCAG contrast on that background. Hosts set `cover_colors` and `cover_text_colors` to a palette, or `:any` for any hex. `cover_text_auto` (default true) adds an Auto choice on the header screen. Writes must be a valid hex, and in palette mode they must be one of those colours. A stored colour that later leaves the palette still renders. A low-contrast pair is allowed; the editor may hint. The cover is not a child, so it cannot be trashed or reordered. The kit editor lists Header and links to the header screen, which saves title, description, cover, and the optional kit location with `revise`. Creating a kit still sets the title only.

When the host root enables companies (`allow: :one`), `Cover::Company` looks up `RecordingStudioCompany.company(root)` and the hero shows `recording_studio_company_logo` plus the name. No capability, or no company, hides that row. One optional Location child on the kit (not a section) shows its icon and `display_name` under the company. `KitLocation` looks that child up and writes it. The header screen edits that place with `recording_studio_location_search_fields`. Blank fields clear it. Flatpack `PageTitle` has no byline slot, and Location's display helper is a Card, so the hero uses Avatar + Icon + text.

An optional cover image sits above the colour header. Enable `ImageLibrary.to` on the host root and `LibraryPlacement.to` on PressKit. `CoverImage` resolves the first `place_library_image` result. `Cover::Image` paints it. Pick it with Attachable's placements screen (`recording_placements_path`) and image picker — no extra upload UI, and no second photo model. Caption, credit, and alt stay on the library photo. Flatpack has no full-bleed crop image, so the hero uses `aspect-[1440/640]` and `object-cover` on a plain `image_tag`.

`RecordingStudioPresskits::Cover::Component` is the reusable card. Pass a kit recording or the title, description, colour, and text colour. Sizes are `:card` (9/16 colour tile, or an image card with the title below the photo), `:preview` (9/16 colour tile in the header editor, no image), and `:hero` (optional full-width image above the colour header). Hero height comes from padding plus content (`p-12` on a phone, `md:p-24` on a desktop), not a fixed ratio. A muted **Press kit** eyebrow sits above the title (`recording_studio_presskits.cover.eyebrow`). The title is `FlatPack::PageTitle::Component` with `size: :display`, top-left, wrapping in `max-w-3xl`. The hero does not show the short description; cards and the header editor still do. Colour grid cards stay 9/16. Text colour is the chosen hex, or Auto.

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

`KitQuery.sections_for` returns the ordered kit sections under a press kit. `KitQuery.section_for` finds one of those by id. `KitQuery.section_content` returns the content child of a kit section. The kit editor, the preview, and the public page walk kit sections in order. `SectionFrameComponent` renders the kit section title and subtitle, then the component registered for the content type. The content component does not render that title or subtitle. A blank title uses `section_heading`, which falls back to `default_section_heading`: the content type label, such as Text, Images, Quotes, Facts & Figures, or Video. The subtitle sits under that heading. The saved title stays blank. A publish recording under the kit is not a section and is not in the kit's orderable children.

`RecordingStudioPresskits::Text` stores HTML from FlatPack's content editor (`preset: :content`, `toolbar: :standard`). A new text section starts with `Text.opening_body` when the body is blank. The content editor shows Body, with Update under it. Title and Subtitle live on the shared heading editor. Trashable is on the text recording and on the kit section. Orderable stays on the kit for kit sections. Publishable stays off both. FlatPack's engine importmap pins TipTap, including the content preset. A host that skips that importmap has to pin those packages itself.

`RecordingStudioPresskits::Images` stores no heading of its own. It holds Attachable `Placement` children only: each child is a library photo plus Orderable position. Enable `LibraryPlacement.to` and `Orderable.to(allows: ["RecordingStudioAttachable::Placement"])` on Images. Do not enable `Attachable.to` on the section. Caption, credit, and alt stay on the library photo. There are no per-kit overrides. The public kit and the editor preview resolve with `LibraryImages` (`Placements.resolve` in placement order) and skip a trashed or missing photo. The same helper paints the kit cover. **Add from library** pushes a picker screen in `pk-editor` (Attachable's picker Stimulus, JSON gallery, and multi-select — not a nested modal). **Upload** writes the file into the workspace library first (`upload_to_library_and_place`), then places it. The default library key is `:default`; hosts can set `config.section_library_keys` per section type. A section refuses a second placement of the same photo. The same photo can sit in another section or kit. Attachable's collection editor (`association: :placements`, list / slides / grid) reorders with `reorder_library_placements!` and **Remove from here** drops the placement only. Editing caption, credit, or alt revises the library photo. A note on the screen says that change shows everywhere the photo is used. Dummy mounts the workspace library with `library_path_for` under Library → Images. Trash-in-use and delete-removes-placements stay Attachable's job. Quote still attaches one image directly. Title, Subtitle, and Update sit on the shared heading editor. An empty images section shows an Add placeholder in the kit editor and stays off the public kit.

Quotes use two recordings under the kit section. `RecordingStudioPresskits::QuoteSection` orders its quotes and stores no heading. Each `RecordingStudioPresskits::Quote` has `body`, `name`, and optional `role` and `organisation`. The UI creates a quotes section with the title Quotes. `create_section!` still takes an optional title. The preview and the public page show Quotes until someone saves a different title. A kit migrated from 0.16 copies the heading Quotes onto the kit section, because that is the heading the public page showed before. The section page uses the shared section editor. **+ Quote** and the quote list sit on the Content tab in column one. Title, Subtitle, and Update sit on Section title, with Update under those fields. + Quote is a primary button with a Heroicons plus icon and the label Quote. Column two, the kit preview, and the public page render each saved quote with `FlatPack::Quote::Component` at `size: :lg`. The citation is the name, role, and organisation. The row shows the quote, truncated to the column, with the name underneath. A blank quote uses Quote on the first line. A blank name leaves the second line off. + Quote opens that quote's edit screen. Orderable is on the quote section for its quotes. Attachable is on Quote for one image, and the upload stays on the quote screen. Publishable stays off the quote section and the quote. A blank body is left off the preview and the public page. Quote stays off the + Section menu because its parent is the quote section.

Facts & Figures use two recordings under the kit section. `RecordingStudioPresskits::FactsSection` orders its facts and stores `display_style` (`list`, `cards`, or `table`, default list) and `columns` (`2`, `3`, or `4`, default 3). Columns apply to cards only. Each `RecordingStudioPresskits::Fact` has a required `label` and `value`, plus optional `unit`, `description`, `source_url`, and `as_of_date`. Value stays text. A source URL, when present, must be HTTP or HTTPS. A kit can hold more than one facts section, each with its own heading and layout. The UI creates a facts section with the title Facts & Figures. `create_section!` still takes an optional title. The preview and the public page show Facts & Figures until someone saves a different title. The section page uses the shared section editor. **+ Fact**, Show as, Columns, and the fact list sit on the Content tab. Title, Subtitle, and Update sit on Section title. + Fact is a primary link with a Heroicons plus icon and the label Fact. It opens a new fact screen. Label, value, and unit are the primary fields. Description, source, and as of sit under More detail. Orderable is on the facts section for its facts. Publishable stays off the facts section and the fact. An empty facts section does not leave a blank preview card. List shows label and value pairs. Cards put the value first, then the label, in the saved column count on larger screens. Table is two columns, Fact and Value. The unit joins the value with a single space, or stays off when it is blank.

Credits are reusable, and the role in a kit is not. `RecordingStudioPresskits::Credit` is a child of the workspace root, next to press kits. It stores `name`, an optional `url`, and an optional `usual_role`. People manage those on **Credits**, linked from Library in the press kit index sidebar. Create and edit go through `RecordingStudioPresskits::Credits`. Trash uses `recording_studio_trashable_trash!`. Restore uses `recording_studio_trashable_restore!`, including from Trashable's trash bin for the workspace. A trashed credit stays out of search and off the public page. Lines that already point at it stay in the section, so restoring the credit puts it back.

A credits section is `RecordingStudioPresskits::CreditsSection` under a kit section, registered with `register_section`. The menu label is Credits and the icon is `user-group`. The kit section still holds the title and subtitle. The section orders `RecordingStudioPresskits::CreditLine` children. A line stores `role` and `credit_recording_id`. It does not copy the name or URL. `Credits.add!` copies `usual_role` into `role` only when the new line has no role of its own. Editing the credit's usual role does not revise existing lines. The same credit can appear in several kits, and more than once in one section, each line with its own role and position. Removing a line trashes that line only. `CreditsSection::Component#render?` is false when no visible line remains, so an empty credits section does not leave a blank preview card.

The credits editor returns true from `below?`. Title, Subtitle, and Update stay on the shared heading editor. In the content editor, the collection editor is its own form. **Save** sits under that table, only as wide as its label. The form uses Flatpack's unsaved-changes controller, and Save is `style: :default` with the submit target. It stays default while the rows match the saved lines and turns primary when they do not. Putting the rows back returns it to default. The editor has no extra heading. **+ Credit** adds a row. The first column searches workspace credits and stores `credit_recording_id`. The search reads `Credits.active_for_root` and matches the name and usual role. No match offers **+ New**, which opens a modal for the name, default role, and URL. The modal label is Default role. The stored field stays `usual_role`. Creating one saves the workspace credit and selects it on the row. The chip shows the name. The second column is **Role on this kit**, a free-text cell on the line. Save walks the rows and calls `Credits.remove!`, `Credits.revise_role!`, and `Credits.add!`. A blank role on a new line still copies `usual_role` inside `Credits.add!`. An existing line updates its role only. Removing a row trashes that line. The credit stays in the workspace. The same credit can sit on two rows. A trashed credit already on a row shows **In the trash**. The preview column follows the rows before Save. Choosing a credit adds that line. A blank role on a new row shows the usual role, which is what Save stores. Typing **Role on this kit** updates the role. Removing a row takes that line out of the preview. Dragging a saved row sends `moving_recording_id` and a 1-based `target_position` and expects `{ ok: true }`, and the preview follows that order. Column two, the kit preview, and the public page list each visible line as the role, then the name. A URL on the credit becomes a link. A trashed credit is omitted there. Publishable stays off the credit, the line, and the credits section.

A video section is the same shape. Press Kits owns `RecordingStudioPresskits::VideoSection`, an empty recording under the kit section. Recording Studio Video owns each `RecordingStudioVideo::Video` child. External Embed owns the provider embed. YouTube ships with External Embed. Another provider appears when the host registers it. Press Kits does not register Vimeo. The section includes Trashable and Videos. It does not include Orderable, so videos stay in the order they were added. Title and subtitle stay on the kit section. + Video sits in the content editor and links to a new video. That screen uses Video's field helper. A saved video also shows Video's player. Removing a video trashes that recording. Removing the section trashes the kit section and the videos under it. Neither path deletes rows.

The kit list row label is the content type, such as Images, Quotes, Facts & Figures, Credits, or Video. A text section with a saved title uses that title. A blank text title stays Text. The label truncates to the column. A saved text title is also the link title, so the full name stays available. The kit section title is the heading on the preview and the public page. When that title is blank, the heading is the content type label. The Title field stays empty and uses that label as its placeholder. A saved title replaces the fallback. The fallback is not enough to show the preview card. The page nav title uses the same heading. The heading on the section editor page is the content type label.

A content editor is a ViewComponent. `initialize` takes the content recording as `recording` and the form path as `update_path`. The class defines `param_key` and `permitted_attributes`. It does not build the page. `SectionEditorComponent` wraps that editor in the content modal. Title and Subtitle stay on `SectionHeadingEditorComponent`. Both forms use Flatpack's unsaved-changes controller. Update is `style: :default` and the submit target. Define `self.below?` and return true when the editor has its own screen controls and cannot share a form. Those editors render `section_actions`, then the editor. An editor that leaves `below?` unset renders inside its own form, with Update under its fields. Text leaves `below?` unset, so Body and its Update sit in the content editor. Images, Quotes, Facts, Credits, and Video return true from `below?`. Text uses `RecordingStudioPresskits::Text::EditComponent`, `param_key` `:text`, and permitted attribute `:body`. Images uses `RecordingStudioPresskits::Images::EditComponent`, `param_key` `:images`, and no permitted attributes. Quotes uses `RecordingStudioPresskits::QuoteSection::EditComponent`, `param_key` `:quote_section`, and `below?` true. Facts uses `RecordingStudioPresskits::FactsSection::EditComponent`, `param_key` `:facts_section`, permitted attributes `display_style` and `columns`, and `below?` true. Credits uses `RecordingStudioPresskits::CreditsSection::EditComponent`, `param_key` `:credits_section`, and `below?` true. Video uses `RecordingStudioPresskits::VideoSection::EditComponent`, `param_key` `:video_section`, permitted attributes empty, and `below?` true. + Video is a link, not a create that records a blank video.

When Recording Studio API is loaded, a press kit exposes show and update. Its payload keys are `title`, `description`, `cover_style`, `cover_color`, and `cover_text_color`. Title and description stay writable on the header screen. Cover style, colour, and text colour are writable on the API. MCP uses the same payload. A missing style reads as `color`. A missing colour reads as the host default. A missing text colour reads as Auto (WCAG contrast on that colour). The press kit also exposes `create_section` and `reorder_sections`. `create_section` takes `content_type`, `title`, and `subtitle` and calls `create_section!`. `reorder_sections` takes `ordered_recording_ids` and calls `recording_studio_orderable_reorder!`. A kit section exposes index, show, and update. Its payload keys are `title`, `subtitle`, `content_type`, and `content_id` for every section. `:videos` is declared on that type as well. The `videos` array is present only when the content is a video section. Each entry has `title`, `url`, `description`, `provider`, `canonical_url`, and `content_type`. A video section's own show payload is that `videos` array. `:display` and `:facts` are declared on the kit section as well. Those keys are present only when the content is a facts section. `display` is `{ style, columns }`. Each fact has `label`, `value`, `unit`, `description`, `source_url`, and `as_of_date`. Optional fields are `null` when blank. Facts stay in Orderable order. Trashed facts stay out. A facts section's own show payload is that `display` object and `facts` array. MCP reads the same structured data through this payload. There is no separate facts API framework. Press Kits does not register `RecordingStudioVideo::Video` with the API. Video already does, including the derived provider fields. The kit section also exposes `remove_section`, which trashes the kit section. Trashable then trashes the content under it. There is no generic kit section create, because a kit section without content would break the one-content rule, and no kit section destroy. Text exposes show and update for `body`. A credit exposes index, show, create, and update for `name`, `url`, and `usual_role`. It does not expose destroy. Trash the credit recording instead, so lines that point at it keep their `credit_recording_id`. A credit line exposes index, show, and update for `role`. Show also returns `name`, `url`, and `credit_id` from the credit when that credit is still active. `add_credit` on the credits section takes `credit_id` and an optional `role` and calls `Credits.add!`. `reorder_credits` takes the same order params as the line list. `remove_credit` on the line trashes that line and leaves the credit. The member actions are `POST .../press_kits/:id/actions/create_section`, `POST .../press_kits/:id/actions/reorder_sections`, `POST .../kit_sections/:id/actions/remove_section`, `POST .../credits_sections/:id/actions/add_credit`, `POST .../credits_sections/:id/actions/reorder_credits`, and `POST .../credit_lines/:id/actions/remove_credit`.

Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits underneath. This gem does not invent its own ACL. Mixin writes authorize through Accessible. Missing access fails closed.

Who can see a live kit is a second axis from published vs draft. Presskits registers Accessible action `presskits.kit_view_full` (default audience `public`, granted roles `view` / `edit` / `admin`). The owner picks that audience on **Who can see this** in `pk-editor`. Accessible stores the audience. Presskits stores only `visibility_fallback` (`preview` or `hidden`, default `preview`) on a sidecar `KitSetting` row keyed by the kit recording — not on the revisioned PressKit, so changing it does not `revise` the kit or fire Publishable `revised`. When the audience is not public, that fallback decides what everyone else sees.

Call `RecordingStudioPresskits::Visibility.presentation_for(actor:, kit:)` from every visitor path. It returns `:full`, `:preview`, `:hidden`, or `:unavailable`. Unpublished kits are unavailable to visitors; owners and editors keep draft preview and edit. Full access is Accessible `authorized_action?` for `presskits.kit_view_full`. Otherwise the kit's fallback applies. Hidden kits 404 without confirming they exist, stay off `KitQuery.discoverable_for(actor:)`, and must not leak metadata. Preview renders only an allowlist: title, short description, cover colour and cover image, company, kit location, and date (the publish time when present, otherwise the kit's created date). No sections, no protected assets, no Download. The preview says why it is limited: sign in, with `config.sign_in_path` (default `/users/sign_in`), or that the visitor needs access. Hosts can add registered audiences such as `presskits.verified_journalist` to the action's `allowed` list. If a workspace constraint removes the selected audience, Accessible falls back to `granted` and the editor shows the audience that is in force.

Non-full public responses set `Cache-Control: private, no-store`. Future fragment caches must include the presentation in the key (`Visibility.fragment_cache_key`). This gem has no public HTTP API or MCP of its own. The optional Recording Studio API payload is for callers who already have recording access. Future serializers must go through the resolver.

Downloads should also require `presskits.kit_view_full` once kit downloads land. Embargoes, access requests, journalist verification, and a unified Locked/Unlocked access UI are later work.

## Screens

The mounted user slice uses Recording Studio's default layout (back and close). Index, the kit editor, the header screen, the section editor, and owner preview are ViewComponents you can reuse or replace.

- Index: the current root's live kits, inside `FlatPack::SidebarLayout::Component`. The heading is **My presskits**. **Presskit** with a Heroicons `plus` icon is first and left. Cards vs table is icon-only `FlatPack::ButtonGroup::Component` (`squares-2x2` / `table-cells`, aria labels only). Do not mint a Press kits toggle. This Flatpack pin's SegmentedButtons is text-only. The sidebar has a collapsible **Library** group (`FlatPack::Sidebar::Group::Component`, open at first). **Images** (`photo`) opens the workspace Attachable library (`library_path_for`). **Credits** (`user-group`) opens the workspace credit list. On a narrow screen, **Open sidebar** shows that group. There is no Credits button beside Presskit. Each card is `Cover::Component` at `:card`: a 9/16 colour tile with a large title on the colour, or an image card with the photo on top (`aspect-[1440/640]`) and the title below. A short description, when present, clamps to two lines. Cards and the table open the kit editor.
- Empty index: what happened, and a way to make a kit.
- Credits: people, companies, and organisations for this workspace. The subtitle is "People, companies and organisations that you credit in Press kits". **+ Credit** is only as wide as its label. The table shows the name. Edit keeps Name, Usual role, and URL. **Save** sits under those fields and is only as wide as its label. **Trash** shares that line, sits on the right, and uses the danger style.
- Kit URL: `GET press_kits/:id` requires edit access and redirects to the kit editor.
- Kit editor. The page is the live kit, full width, the same rendering as the public kit, inside one Flatpack Card. The kit header is `Cover::Component` at `:hero`. A slim toolbar holds **Section** (Heroicons `plus`, primary), **Order**, and `render_publishable_quick_actions`. **Section** opens a modal list of registered content types and adds at the end, or into an empty kit. Each row has the type on the first line (Text, Images, Quotes, Facts & Figures, Credits, Video) and a short line on why that block helps a press kit. Text uses `document-text`, Images uses `photo`, Quotes uses `chat-bubble-bottom-center-text`, Facts & Figures uses `calculator`, Credits uses `user-group`, and Video uses `video-camera`. A host content type defines `self.section_menu_icon` to supply its own. Choosing one calls `create_section!` with that type's label as the title, then stays on the kit. Orderable places it after the current section or at the end. The new section scrolls into view and highlights. A Flatpack toast offers **Undo**, which trashes it. There is no title form and no **Save** on this page. The preview lays out like the public kit. On a pointer that can hover, hover or focus-within tints a region with `--surface-muted-background-color` and shows the FAB. Keyboard focus uses `:focus-visible` only, and still reveals the FAB. On touch (`@media (hover: none)`), a tap makes that section or the header the active region — tint and FAB then. Tapping another region moves the active state. Tapping outside clears it. Flatpack has no tap-to-activate or hover-only visibility API, so a small Stimulus controller (`recording-studio-presskits--editor-chrome`) owns the touch active state. The `:hero` cover is a flush colour surface (no nested Card, `rounded-none`) that runs to the kit card's top and side edges. The kit card uses `padding: :none` and has no inner section pad or gap. The preview clips with `overflow-hidden` and `rounded-[var(--radius-lg)]` so the card radius cuts the cover and the last section tint. Title and description sit at the top of the hero (`justify-start`) with `p-8 md:p-12` as the inset. The title is `FlatPack::PageTitle::Component` with `size: :display` in a `max-w-2xl` block. Each section shows a contained `FlatPack::Fab::Component` (`size: :sm`, `icon: :plus`, `position: :top_right`, `backdrop: false`, `offset: "1rem"`) on a `position: relative` region with `p-8 md:p-10 lg:p-12` and `rounded-none`, so the muted tint runs flush to the card sides. Phone padding stays `p-8`. Vertical pad is the only space between sections. Sections add `pr-20` so the heading clears the FAB. The kit header uses the same FAB, pinned inside the cover with `offset: "1rem"`. Header hover and tap use an inset overlay (`color-mix` black at 16%) instead of a surrounding muted tint, so the colour still bleeds to the card. The public kit uses the same unpadded card, flush hero, and section-owned pad. Top corners open downward. Section actions: **Edit title** (shared heading screen), **Edit content**, **Reorder** (existing Reorder modal, fragment on this section), **Trash** (`style: :danger`, Trashable plus confirm), and **Add new section** (the same picker, below this one). Header actions: **Edit heading**, **Cover colours**, **Who can see this**, and **Cover image**. **Cover image** opens Attachable's placements picker (`place_library_image`) and returns to the kit. Those editors open one navigable `FlatPack::Modal::Component` (`id: "pk-editor"`, `navigable: true`, `size: :lg`). The first screen loads from `src` into turbo frame `pk-editor-screen`. Heading, content, and child screens (`facts`, quotes, videos, credits) wrap in `flat_pack_modal_screen`. Drill-down links and create forms use `data-fp-nav="push"`. Back re-fetches the previous screen. Do not nest modals, and do not add a custom stack or unsaved-close guard — Flatpack has not shipped save-complete or unsaved protection yet. Empty sections show an Add placeholder in the editor. Public kits skip sections with nothing to show. **Order** opens **Reorder**, a separate modal with the Orderable list (`orderable: true`, `divider: true`, `orderable_url` posting `moving_recording_id` and a 1-based `target_position`). That route calls `recording_studio_orderable_move!`. Each row is a kit section. The link opens content. The link text is the content type, such as **Images**, **Quotes**, or **Facts & Figures**. A text section with a saved title uses that title. A blank text title stays **Text**. The label uses `truncate`. Remove is an icon-only trash button. Saves refresh the changed section behind the modal with Turbo streams and stay on the current screen. Those save forms use `data-turbo-frame="_top"` so the navigable screen frame does not swallow the stream. Types come from `picker_types`. **+ Access** stays on this page.
- Visibility. **Who can see this** on the kit cover FAB opens a screen in `pk-editor`. **Who can view the full press kit?** is a Flatpack Select of Accessible `audience_options_for` after host and workspace constraints. Default is Public. When that is not Public, **What should other visitors see?** is a Flatpack RadioGroup (`variant: :cards`): Preview or Hidden. Switching back to Public hides the fallback control and keeps the stored fallback. There is no Locked/Unlocked switch. Saving calls Accessible `set_audience!` and `KitSettings.save_fallback!`. Direct `GET` of the screen still works, with Back to kit.
- Header. **Edit heading** or **Cover colours** on the kit cover FAB opens Title, Short description, kit location, **Cover image**, **Colour**, and **Text colour** as a screen in `pk-editor`. Title is required. Short description is optional, with a 280 character count. **Cover image** is **Choose from the library** and opens Attachable's placements screen. Colour is a `FlatPack::RadioGroup` (`variant: :swatches`, `size: :md`) of the host palette, or a `FlatPack::ColorSwatch` when `cover_colors` is `:any`. Text colour is the same, plus **Auto** as its own radio when `cover_text_auto` is on (`nil` then uses WCAG contrast). Swatch labels are the accessible name and the tooltip. A `Cover::Component` preview tile follows the colours as you edit and stays 9/16 without the photo. Update starts in the default style and turns primary when the form changes. Saving uses `revise` and refreshes the kit header with Turbo streams. Direct `GET` of the header screen still works, with Back to kit. **+ Access** stays off.
- Heading editor. `GET sections/:id/heading` is one shared form for every section type. The modal title is **Section heading**. Title, Subtitle, then **Update**. There is no Heading group. Update starts in the default style and turns primary when Title or Subtitle no longer matches the saved value. `SectionHeadingComponent` renders those fields on the public kit and in the editor preview through Flatpack `SectionTitle` (`size:`, `spacing:`, `level:`). A blank title uses `section_heading`, which falls back to the content type label.
- Content editor. The content screen (or the direct section URL) holds that section's editor only. Quotes puts **+ Quote** there, then the quote list. A quote row or **+ Quote** pushes Edit quote. Facts puts Show as, Columns when the style is Cards, **+ Fact**, then the fact list. **+ Fact** and a fact row push the fact screen. Video puts **+ Video**, then the video list. Images puts **Add from library** and **Upload**, then Attachable's placements collection editor (list, slides, grid). **Add from library** pushes the picker screen in the same `pk-editor` modal. Credits puts a collection editor. **+ Credit** adds a row. **Save** under the table stores the lines. CollectionEditor's inline create still uses Flatpack's own create dialog. Text puts the FlatPack content editor there, labeled Body, with Update under it. There is no preview column on this screen. **+ Access** stays off.
- Owner preview: the same public page, on the default layout, for an authenticated owner. Back returns to the kit editor. A kit that is not live stays hidden from logged-out visitors.

Default-layout chrome is back, close, and page actions. **+ Access** is in the right slot on the kit editor only. Index, the new form, the header screen, the section editor, and owner preview leave that slot empty. Do not put Sign in, Sign out, or Root Switchable there. Core owns back and close.

Primary buttons: **Presskit** (Heroicons plus) on the index, **Create** on the new form, and **Section** on kit edit. Heading and header **Update** start in the default style and turn primary when that form changes. Content has one when the editor saves its own fields there, such as Body. Credits **Save** does the same under the credit table. Publish state stays on Publishable's own action. Do not hand-roll a second publish system.

## Public

A live kit is readable without signing in. Publishable serves `/published/:uuid/:slug` (override the path only if it still includes `:uuid`). `.to` sets `public_layout: "recording_studio_presskits/blank"`. That layout is a document and the kit: no back, no close, and no TopNav. The page title is the kit name. The kit opens inside the same Flatpack Card as the editor. `Cover::Component` at `:hero` is an optional full-width cover image (`aspect-[1440/640]`) above a flush colour header. Height of the colour band comes from `p-12 md:p-24` plus the eyebrow and title. The title is `PageTitle` `size: :display` in a wrapping `max-w-3xl` block. The short description stays off that band. View and the publish menu Preview both use it. Owner preview stays on `recording_studio/default_layout`.

Logged-out visitors get a 404 for a kit that is not currently published. An authenticated owner can still open the owner preview on the default layout. A live kit whose audience is not public still goes through `Visibility.presentation_for`. Preview shows the allowlisted header fields and an explanation. Hidden is a plain 404.

Use `PressKit.indexable` / `indexable?` for publish state. Use `KitQuery.discoverable_for(actor:)` for public lists, search, and discovery so hidden kits stay out for people who cannot view the full kit. Preview kits may show their preview card. Admin widgets still list live vs not-live work for staff.

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
| Recording Studio | `v4.4.0` |
| Accessible | `v0.14.0` |
| Admin | `v2.1.0` |
| Root Switchable | `v0.6.0` |
| FlatPack | `v0.1.224` |
| Attachable | `v0.13.0` |
| Company | `v0.3.0` |
| Location | `v0.5.1` |
| Orderable | `v0.2.7` |
| Trashable | `v0.6.0` |
| Duplicatable | `v0.4.5` |
| Publishable | `v0.7.0` |
| External Embed | `v0.1.4` |
| Video | `v0.1.1` |
| Metrics | `v0.2.0` |

Authenticated dummy screens keep `RecordingStudio::UsesDefaultLayout`. Core 4.4 puts `data-theme` on `<body>`; dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps index, the kit editor, owner preview, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables` — not a custom theme. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack `anchor_href` for the close X. The layout draws one back control. A screen that sets a back URL gets that link. A screen that does not gets PageNav's history button. Core still stores the close path in `page_nav_anchor_url` and the back path in `page_nav_back_url`. After sign-in, `/` redirects to the press kit index. Dummy Tailwind scans FlatPack, Recording Studio, Admin, Publishable, Attachable, Company, Location, and this gem so that layout is not an unstyled box.

The public kit view uses `recording_studio_presskits/blank` instead. Do not use Publishable's empty TopNav there. Do not insert Sign in, Sign out, or Root Switchable into PageNav. Core owns back and close on the default layout. **+ Access** is in the slot on the kit editor only. Cards, table, the kit editor, the header screen, public show, owner preview, and Admin live in `docs/dummy-screenshots/`. After seed: `press-kit-index-cards.png`, `press-kit-index-table.png`, `workspace-kit-edit.png`, `workspace-kit-edit-mobile.png`, `workspace-heading-edit.png`, `workspace-content-edit.png`, `workspace-fact-drilldown.png`, `workspace-header-edit.png`, `workspace-kit-show.png`, `public-press-kit-show.png` and `public-press-kit-show-mobile.png` (logged-out Spring launch), `hero-restyle-editor-desktop.png` / `hero-restyle-public-desktop.png` plus mobile and crop companions, `hero-company-editor-desktop.png` / `hero-company-public-desktop.png` plus mobile and crop companions (company + kit location on the colour header), `hero-cover-image-editor-desktop.png` / `hero-cover-image-public-desktop.png` plus mobile and crop companions, `hero-cover-colour-editor-desktop.png` / `hero-cover-colour-public-desktop.png` plus mobile and crop companions, `hero-cover-grid-desktop.png` / `hero-cover-grid-mobile.png`, `owner-preview-unpublished.png` (owner preview of Autumn recap), and `admin-press-kits.png` (live vs not-live). Do not recapture dummy home.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seeds one published kit titled **Spring launch**, with a short description, a sky cover (`#BFDBFE`, Auto dark text), a Harbour Gallery cover photo from the workspace image library, **Harbour Studio** as the workspace company, **Harbour Gallery** as the kit location, credits, company statistics as cards, and project specifications as a list, and one unpublished kit titled **Autumn recap**. Dummy Workspace enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests. It also enables `Companies.to(allow: :one)` and `ImageLibrary.to`. Dummy `FakeBlock` stays test-only. Its parent is a kit section. It enables Trashable so remove is testable, it is excluded from the add dropdown, and it does not enable Publishable. Its `prepare` hook sets the block title from the create heading, or to Block when that heading is blank. The seeded admin user gets Accessible owner access on the workspace and the admin root.

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
