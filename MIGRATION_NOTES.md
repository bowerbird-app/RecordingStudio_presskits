# Upgrade notes

## 0.26.0

The kit editor preview matches the public kit. In-flow **Edit heading**, **Edit content**, and the compact add-section dropdown are gone. On a pointer that can hover, hover or focus-within tints the region with `--surface-muted-background-color` and shows the FAB. Keyboard users get a `:focus-visible` outline and still see the FAB. On touch, the FAB is not always visible. A tap makes that section or the header the active region (tint and FAB). Tapping another region moves the active state. Tapping outside clears it.

Each section has `FlatPack::Fab::Component.new(contained: true, position: :top_right, backdrop: false, size: :sm, icon: :plus, label: "Section actions")` on a `position: relative` region so the FAB pins to that section. Top corners open downward. Speed-dial actions:

- **Edit title** — shared heading screen in `pk-editor`
- **Edit content** — that section's content screen
- **Reorder** — existing Reorder modal, fragment focused on this section when the browser honors it
- **Trash** — `style: :danger`, `DELETE` through Trashable, with `data-turbo-confirm`
- **Add new section** — the section picker, with `after_recording_id` so the new block lands below this one

The kit header FAB uses the same chrome: **Edit heading** and **Cover colours**. Both open the shared header screen. Cover colours hashes to `#presskits-header-colours`. The toolbar **Section** button still adds at the end or into an empty kit.

Bump FlatPack to `>= 0.1.222` (dummy tag `v0.1.222`) and rebuild Tailwind so `size: :sm` and action `style: :danger` generate. Reload Flatpack CSS after the bump. Hosts that replaced those components should render the Flatpack FAB (`icon: :plus`) and drop the old ghost buttons. FAB has no hover-only visibility or tap-to-activate API. Desktop uses group-hover / focus-within. Touch uses `recording-studio-presskits--editor-chrome` and `data-pk-edit-active`.

## 0.25.1

Bump FlatPack to `>= 0.1.221` (dummy tag `v0.1.221`) and rebuild Tailwind so the swatch utilities generate. Reload Flatpack CSS after the bump.

Palette **Colour** and **Text colour** on the shared kit header screen use `FlatPack::RadioGroup` `variant: :swatches` (`size: :md`). The option label is the accessible name and the tooltip. `:any` still uses `FlatPack::ColorSwatch`. Text colour **Auto** stays a separate inline radio with the same field name — swatches need a CSS colour, and `auto` is not one. A host that replaced that screen should render the same.

Dummy and gemspec pins move to the latest GitHub releases: Accessible `0.12.1`, Attachable `0.12.0`, Orderable `0.2.7`, Trashable `0.5.0`, Duplicatable `0.4.5`, Publishable `0.5.0`, External Embed `0.1.4`, Video `0.1.1`, Root Switchable `v0.5.6`. Recording Studio stays `v4.3.0`. Admin stays `v2.0.7`. Location and Lists are not Presskits dependencies.

Bump Accessible to `~> 0.12`, Attachable to `~> 0.12`, Publishable to `~> 0.5`, and Trashable to `~> 0.5`. Run `bin/rails generate recording_studio_attachable:migrations` and `db:migrate` for the new library and placement tables. Add `RecordingStudioAttachable::Library` and `RecordingStudioAttachable::Placement` to `config.recordable_types`. Press kit Images still attach files under the section.

## 0.25.0

A press kit can store a colour cover. `cover_style` is `color` for now (`nil` means colour with the host default). `cover_color` is a hex string. `cover_text_color` is an optional hex for the title and description. `nil` text colour is Auto: light or dark from WCAG contrast.

Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The migration adds nullable `cover_style`, `cover_color`, and `cover_text_color` on `recording_studio_press_kits`. Existing kits keep their title and render the default colour with Auto text.

Hosts set `config.cover_colors` to a palette or `:any`, and `config.default_cover_color`. The default palette is `#1F2937`, `#7C3AED`, `#DB2777`, `#059669`, and `#D97706`. The default colour is `#1F2937`. `cover_text_colors` defaults to `#F8FAFC`, `#111827`, `#E5E7EB`, and `#6B7280`, or `:any`. `cover_text_auto` (default true) adds an Auto choice. Writes must be a valid hex. In palette mode they must be one of those colours. A stored colour that later leaves the palette still renders.

A low-contrast text colour is allowed. The header editor may hint.

`RecordingStudioPresskits::Cover::Component` paints `:card` and `:preview` as 9/16 story tiles, and `:hero` as a wide 21/9 band on the public kit. A full-width 9/16 hero would bury the kit. Title sits on the colour at the page-title size. A card description clamps to two lines. Press Centers and hosts can render the same card.

The shared kit header screen in `pk-editor` adds **Colour** and **Text colour**. A palette uses `FlatPack::RadioGroup` `variant: :swatches`. `:any` uses `FlatPack::ColorSwatch`. Text colour includes **Auto** as its own control. A preview tile follows the cover live. The kit header on the live editor uses the same `Cover::Component` at `:hero` and refreshes through the existing Turbo Stream save.

When Recording Studio API is loaded, a press kit show and update include `cover_style`, `cover_color`, and `cover_text_color`. Those keys are writable. Title and description stay on the header screen. MCP uses the same payload. Duplicating a kit copies those fields.

Reload the press kits JavaScript so the header preview follows Colour and Text colour. Importmap hosts that already pin Flatpack controllers load `flat-pack--color-swatch` with no new register call.

## 0.23.0

The press kit index draws a sidebar. Library is a collapsible group, and Credits is the link under it. The Credits button next to Presskit is gone.

The credits list shows each name. Usual role and URL stay on the credit form. Save sits under those fields. Trash shares that line, on the right, in the danger style.

## 0.22.1

The dummy default layout draws one back control. A screen that sets `page_nav_back_url` gets that link. A screen that does not gets PageNav's history button. Close stays on `anchor_href`.

If a host copied the earlier dummy layout, remove the line that assigns `page_nav_back_url` to `secondary_anchor_href`. That second control used the same chevron as PageNav's history button.

## 0.22.0

Facts & Figures is a press kit section. The facts section stores how the facts look. Each fact is its own recording.

Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The migration adds two tables and does not change existing kit rows.

`recording_studio_facts_sections` stores `display_style` (`list`, `cards`, or `table`, default `list`) and `columns` (`2`, `3`, or `4`, default `3`). Columns apply when the style is cards. `recording_studio_facts` stores `label`, `value`, optional `unit`, `description`, `source_url`, and `as_of_date`. There is no foreign key between the tables. The recording tree is the parent.

Add these to `config.recordable_types`:

```ruby
"RecordingStudioPresskits::FactsSection",
"RecordingStudioPresskits::Fact"
```

`FactsSection` allows a kit section. `Fact` allows a facts section. Orderable on the facts section allows facts. Trashable is on both. Publishable and Duplicatable stay off them. Duplicating a kit copies the facts section, its display settings, and the facts in order.

Create the section with `RecordingStudioPresskits.create_section!`. Record a fact under the facts section. Revise display settings on the facts section. Reorder with `recording_studio_orderable_reorder!` or `recording_studio_orderable_move!` on the facts section. Trash a fact with `recording_studio_trashable_trash!`.

The kit section payload keeps `title`, `subtitle`, `content_type`, and `content_id`. A facts section also includes `display` and `facts`. MCP uses that same payload. List, cards, and table are the only layouts.

## 0.21.0

Credits belong to the workspace. A line in a press kit only says what that credit did on that kit.

Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The migration adds three tables and does not change existing kit rows.

`recording_studio_credits` stores `name`, optional `url`, and optional `usual_role`. The column is `usual_role` because Active Record already uses `default_role` for the database connection. The new credit modal labels that field Default role. `recording_studio_credits_sections` is the section content under a kit section, the same shape as a quote section. `recording_studio_credit_lines` stores `role` and `credit_recording_id`. The name and URL stay on the credit. `Credits.add!` copies `usual_role` onto a new line when that line has no role yet. Later edits to `usual_role` do not revise existing lines.

Add these to `config.recordable_types`:

```ruby
"RecordingStudioPresskits::Credit",
"RecordingStudioPresskits::CreditsSection",
"RecordingStudioPresskits::CreditLine"
```

`Credit` allows the same parent as a press kit, `RecordingStudioPresskits.parent_root_type`. `CreditsSection` allows a kit section. `CreditLine` allows a credits section. Orderable on the credits section allows credit lines. Trashable is on all three. Publishable and Duplicatable stay off them. Duplicating a kit copies the lines and keeps each `credit_recording_id`, so the copy still points at the workspace credits.

Trash a credit with `recording_studio_trashable_trash!`. Restore it with `recording_studio_trashable_restore!`. The line stays. The public page skips a line whose credit is trashed or missing. Restoring the credit shows that line again. Removing a line trashes the line only.

Create credits with `RecordingStudioPresskits::Credits.create!` on the workspace root. Add one to a section with `Credits.add!`. Revise the reusable fields with `Credits.revise!`. Revise one kit's role with `Credits.revise_role!`. List the workspace credits with `Credits.active_for_root`. A credit from another root is refused.

The screens are `GET /credits` for the workspace list, and the Credits item in + Section for a kit. Title and Subtitle stay on the Section title tab. On Content, a collection editor adds each line. The first column searches `GET /credits/search` and creates with `POST /credits` when the response is JSON. The second column is the role on this kit. **Save** sits under the table and patches the lines. It starts in the default style and turns primary when the rows no longer match the saved lines. A blank role on a new line still copies `usual_role`. The preview column follows a chosen credit, a role edit, and a removed row before Save. A blank role on a new row shows that usual role. Dragging a saved row patches `moving_recording_id` and a 1-based `target_position`. The response is `{ ok: true }`. The preview follows that order too. `recording_id` with `before_recording_id` or `after_recording_id` still reorders a line. Reload the press kits JavaScript with this version.

When Recording Studio API is loaded, credits expose index, show, create, and update. There is no credit destroy operation. Trash the recording so existing lines keep their id. `add_credit` and `reorder_credits` are on the credits section. `remove_credit` is on the line. A line's show payload is `role`, `name`, `url`, and `credit_id`. `name` and `url` are read from the credit when it is still active. The kit section payload keeps `title`, `subtitle`, `content_type`, and `content_id`. A video section also includes `videos`.

Bump FlatPack to `>= 0.1.204` (dummy tag `v0.1.204`). Reload kit CSS and JavaScript. `style:` on FlatPack tabs is a button style name. This gem does not pass a CSS string there. Select wrappers also include `flat-pack-input-wrapper`. The credits section uses the collection editor. Importmap hosts that already pin Flatpack controllers load it with no new register call. `CreditsSection::Component#render?` is false when no visible line remains, so an empty credits section does not show a preview card.

## 0.20.0

A press kit can hold a video section. Press Kits owns the section. Recording Studio Video owns the recording. External Embed owns provider embeds.

YouTube ships with External Embed. Other providers appear when the host registers them, before External Embed freezes its catalog. Press Kits does not register Vimeo, and it does not call `RecordingStudio::ExternalEmbed.register`.

Add both gems:

```ruby
gem "recording_studio_external_embed", "~> 0.1.1", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.3"
gem "recording_studio_video", "~> 0.1.0", github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.0"
```

The `v0.1.3` tag still reports External Embed `VERSION` as `0.1.1`. The gemspec constraint follows that constant. The Gemfile pins the tag.

Add both recordable types:

```ruby
"RecordingStudioPresskits::VideoSection",
"RecordingStudioVideo::Video"
```

Run the Video generators, then the Press Kits migrations generator, then migrate:

```bash
bin/rails generate recording_studio_video:install
bin/rails generate recording_studio_video:migrations
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

`recording_studio_video_sections` is a new empty table: a UUID primary key and `created_at`. `recording_studio_videos` belongs to Video (`title`, `url`, `description`, `created_at`). External Embed has no table and no migrations generator.

`VideoSection` includes Trashable and `RecordingStudio::Capabilities::Videos.to`. It does not include Orderable. Kit sections stay the only ordered children of a press kit. Videos follow `created_at`. The editor sets `below?` to true, so + Video and the video list sit on the Content tab. + Video links to a new video. A blank video cannot be recorded. Title, URL, and description use Video's field helper. A saved video shows Video's player. Removing one video trashes that recording and leaves the section. Removing the section trashes the kit section, the video section, and its videos. `trash_root` is set on the kit section. Rows stay in the database.

When Recording Studio API is loaded, a kit section still returns `title`, `subtitle`, `content_type`, and `content_id`. `:videos` is declared on that output. The array is included only when the content type is `RecordingStudioPresskits::VideoSection`. A video entry always has `title`, `url`, `description`, `provider`, `canonical_url`, and `content_type`. The video section type returns `{ videos: ... }`. Do not register `RecordingStudioVideo::Video` again from the host or from Press Kits. Video already registers that type, including the derived provider fields.

Kit section rows on the kit editor use the section menu icon instead of `arrows-up-down`. Header and section rows pass `class: "!items-center"` on `FlatPack::List::Item`. That is the class this Flatpack pin uses to center a row. Drag to reorder is unchanged. A text section with a saved title uses that title as the row label. A blank text title stays Text. The label truncates to the column, and the saved title is the link title. Images, Quotes, Video, and host types stay on the content type label. A host that replaced `ChildComponent` should do the same.

A blank kit section title stays blank. The preview, the public page, and the page nav use `RecordingStudioPresskits.section_heading`, which falls back to `default_section_heading`: the content type label. The Title field placeholder is that label. A saved title replaces it. The fallback does not show the preview card by itself. A host that replaced `SectionFrameComponent` should use `section_heading` for the visible title and keep the card behind the saved-title check.

The section editor still has two columns. The preview card is omitted until the section has a saved title, a subtitle, or content that would show. `SectionFrameComponent#render?` is that check. Text, Images, Quotes, and Video implement `render?` and return false when the body, photos, quotes, or videos are empty. A host content component can do the same. The default is still to render. The kit editor hides its preview card on the same check. A host that replaced `SectionEditorComponent` should wrap the preview card in `show_preview?` rather than always rendering it.

Bump FlatPack to `>= 0.1.202` (dummy tag `v0.1.202`). Every section editor uses `FlatPack::Tabs::Component` with `variant: :pills` and `style: :default`. The pills are Content and Section title. Content is selected first. Section title is Title, Subtitle, and Update under those fields. There is no Heading group. Keep `flat-pack--unsaved-changes` on that form, and keep Update as `style: :default` with the submit target. `style:` on the tabs is a button style name. Do not pass a CSS string.

Content holds the section editor. `section_actions` and a `below?` editor stay on Content, outside the title form. An editor that does not set `below?` renders on Content in its own form, with Update under its fields. Text does that, so Body saves without Title and Subtitle, and Title saves without the body. A host that replaced `SectionEditorComponent` follows this split. Saving either form still posts to the kit section update. Sending only `kit_section` leaves the body alone. Sending only the content key leaves the title and subtitle alone.

## 0.19.0

Bump FlatPack to `>= 0.1.200` (dummy tag `v0.1.200`). The section heading form, the one with Title and Subtitle, uses Flatpack's unsaved-changes behaviour. Update starts in the default style and turns primary when a field in that form no longer matches the saved value. Typing the saved value back returns the button to default. Saving and coming back to the same screen does too, because the new page captures a new baseline.

Importmap hosts that already pin Flatpack controllers load `flat-pack--unsaved-changes` with no new register call. A bundled app that copies the esbuild list in Flatpack's installation doc registers `UnsavedChangesController` as `flat-pack--unsaved-changes`.

Reload Flatpack CSS and JavaScript. FlatPack `0.1.199` also changes how an orderable list drags and makes those rows slightly taller. The Ruby calls stay the same. Rebuild host Tailwind so the new list spacing utilities are generated.

A host that replaced `SectionEditorComponent` adds the controller on that heading form and marks Update as the submit target with `style: :default`. Header Update and a quote's Save stay primary.

## 0.18.0

Every section editor draws one heading form. Update sits above Title, Subtitle, and any extra fields. That button is in the same spot for Text, Images, and Quotes.

A content editor renders inside the form, under those fields, unless the class defines `self.below?` and returns true. Text does not, so Body stays in the form. Images and Quotes return true. Upload and the photo editor sit under the form. + Quote and the quote list sit under the form. `section_actions` still renders between the heading form and a `below?` editor.

Remove `form?`. It no longer changes the page. An editor that returned false from `form?` now needs `self.below?` so its own forms and uploads stay outside the heading form.

## 0.17.0

A press kit section is a kit section. The content recording sits under it.

Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The migration is irreversible. `down` raises `ActiveRecord::IrreversibleMigration`.

`recording_studio_kit_sections` is a new table with nullable `title` and `subtitle`. The migration wraps each direct child of a press kit whose type is Text, Images, QuoteSection, or another type already passed to `register_section`. It records a kit section, copies `recording_studio_orderable_position` onto that kit section, and sets the content recording's parent with `Recording#update!`. `record!` ignores `parent_recording` on an existing recording, so the move cannot use `record` or `revise`. `update!` still checks that the declared parent allows the content type. The copy of the position is not an Orderable reorder. Reorder needs an actor, and the kit's `allows` list is only kit sections, so a publishable sibling would be left out of a reorder anyway.

Text titles move onto the kit section. `recording_studio_texts` then drops `title`. The body stays. Image titles and subtitles move onto the kit section. `recording_studio_images` then drops `title` and `subtitle`. Photo attachments stay on the images recording. A quote section has no stored heading. The migration sets that kit section's title to Quotes, which is the heading the public page showed before. A quotes section created after this release starts with a blank title. Nested quotes stay under the quote section. Trashed content stays trashed. If that content recording was the trash root, the new kit section becomes the trash root and the content recording clears `trash_root`. Running the migration again does not wrap a recording that already sits under a kit section.

Add `"RecordingStudioPresskits::KitSection"` to `config.recordable_types`. Change content `allowed_parent_types` from the press kit to the kit section.

```ruby
allowed_parent_types: ["RecordingStudioPresskits::KitSection"]
```

Create a section with `RecordingStudioPresskits.create_section!`. Stop calling `kit.record(SomeSection, parent_recording: kit)` for section content. `register_section` registers content that can live inside a kit section. It accepts `component`, `editor`, and `prepare`. `KitQuery.live_children` is gone. Use `KitQuery.sections_for` for the kit sections under a press kit, and `KitQuery.section_content` for the content child.

Orderable on the press kit allows only kit sections. Reorder those recordings. Do not reorder text, images, or quote sections as children of the press kit. A publishable child under the kit is no longer mixed into that order.

Section editors do not show Cancel. Back still returns to the kit. The header screen and a quote's own edit screen still show Cancel.

Every section editor is the same two-column template. Column one holds Title, Subtitle, the section buttons, and the content editor. Column two is the preview, including Text. `preview?` on a content editor no longer changes that page. Remove it. `form?` returning false still saves Title and Subtitle on their own form, in column one, because a second form cannot nest inside it.

When Recording Studio API is loaded, a press kit exposes show for `title` and `description`. Update those on the header screen. `create_section` on the press kit takes `content_type`, `title`, and `subtitle` and calls `create_section!`. `reorder_sections` takes `ordered_recording_ids` and calls `recording_studio_orderable_reorder!`. Both actions are registered against Orderable, which the press kit already enables. `remove_section` on the kit section calls `recording_studio_trashable_trash!`. That action is registered against Trashable. Orderable and Trashable do not ship these actions, so this gem registers the wrappers. A kit section still exposes index, show, and update. The show payload has `title`, `subtitle`, `content_type`, and `content_id`. Update a text body on the text recording. There is no generic kit section create and no kit section destroy. The editor removes a section by trashing the kit section, and `remove_section` does the same.

## 0.16.0

An images section has an optional `title` and `subtitle` instead of a section caption. Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. `recording_studio_images` drops `caption` and gains nullable `title` and `subtitle` text columns. An existing section caption is copied into `title`. Subtitle starts empty. A blank title or subtitle is stored as nothing. The editor labels are Title and Subtitle, in column one. Column two is a preview of that section inside a FlatPack card, with no card header. The kit row stays Images. The kit preview and the public page show the title with FlatPack's section title and its anchor, and the subtitle under that title, when the title is present. Each photo still keeps caption, credit, and alt text on the attachment.

A kit section is registered with `RecordingStudioPresskits.register_section`. Declaring the press kit as an allowed parent does not make a recording a section. Text, Images, and Quotes are registered by the gem. Register a host section the same way, and keep `allowed_parent_types` so it can be recorded under the kit. `excluded_picker_types` only hides it from + Section. The editor, preview, and public page show registered sections. Other children stay under the kit. Reordering a section leaves those children in place.

## 0.15.0

The kit header is the press kit: required `title`, optional `description`. It is not a child section.

Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. `recording_studio_press_kits` gains a nullable `description` text column. Existing kits keep their title and start with no description. Creating a kit still asks only for the name.

The kit editor lists Header with the sections. That row opens `GET press_kits/:press_kit_id/header/edit`, a two-column screen: the fields, then a preview. `PATCH press_kits/:press_kit_id/header` revises `title` and `description`. `PATCH press_kits/:id` is no longer a route. A blank description is stored as nothing. 280 characters is the limit. The row is not orderable and not trashable.

A dummy database migrated on 0.14.0 already has `20261006120000` (text section title). This release keeps that migration file, so migrate and rollback can see it. Do not delete it to clear the error.

Bump FlatPack to `>= 0.1.198` (dummy tag `v0.1.198`). Link `stylesheet_link_tag "flat_pack/application"` beside `flat_pack/variables` on host layouts. FlatPack 0.1.198 paints a primary button from that sheet. The public blank layout already links it. Dummy sign-in and the default layout do too.

Bump Accessible to `~> 0.11` (dummy tag `v0.11.1`). Run `bin/rails generate recording_studio_accessible:migrations`, then `bin/rails db:migrate`. Access `role` is a string (`view`, `edit`, `admin`). 0.8.0 adds `depends_on_recording_id`. 0.10.0 adds access invitations. Grant through `bootstrap_owner_access!` / `grant_access`; `RecordingStudio::Access` is readonly.

Bump Publishable to `~> 0.4` (dummy tag `v0.4.2`). Admin dummy tag `v2.0.4`. Attachable `v0.7.1`. Duplicatable `v0.4.3`. Orderable `v0.2.5`. Trashable `v0.4.4`. Root Switchable (dummy) `v0.5.3`. Recording Studio stays `v4.2.2`.

## 0.14.0

A text section has an optional `title`. Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. `recording_studio_texts` gains a nullable `title` text column. Existing sections start with no title. A blank title is stored as nothing. The editor labels are Title and Body. The kit row stays the section type. The kit preview and the public page show the title with FlatPack's section title and its anchor when it is present. The title is no longer taken from the first line of the body.

The + Section menu shows a Heroicon beside Text (`document-text`), Images (`photo`), and Quotes (`chat-bubble-bottom-center-text`). A host section can define `self.section_menu_icon`. No migration for the icons.

## 0.13.0

Images editor uses Attachable's collection editor for each photo.

Bump `recording_studio_attachable` to `~> 0.7` (dummy tag `v0.7.0`) and FlatPack to `>= 0.1.135` (dummy tag `v0.1.135`). Run `bin/rails generate recording_studio_attachable:migrations`, then `bin/rails db:migrate`. Attachment rows gain `root_recording_id`, `caption`, `credit`, and `alt_text`. The section caption stays on `recording_studio_images`. Do not enable Attachable on PressKit.

## 0.12.0

Quote display.

No host or schema changes. A quote row shows the quote, truncated to the column, with the name underneath. The quotes action is + Quote. Column two, the kit preview, and the public page render each quote with FlatPack's quote component at large size. The citation is the name, role, and organisation.

## 0.11.0

Quotes section.

Add `"RecordingStudioPresskits::QuoteSection"` and `"RecordingStudioPresskits::Quote"` to `config.recordable_types`. Run `rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. Orderable is on the quote section for its quotes. Attachable is on Quote for one image. Publishable stays off both.

## 0.10.0

Images section. Attachable is 0.4.

Images is a press kit section. Add `"RecordingStudioPresskits::Images"` to `config.recordable_types`. Run `rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The new table is `recording_studio_images` (`caption`, `created_at`).

The section includes Attachable for images only. Depend on `recording_studio_attachable`, `~> 0.4`, mount it, and keep Active Storage direct uploads wired. Do not enable Attachable on PressKit. Each photo is an attachment recording under the Images section. Removing one photo calls Attachable's remove and stays on the section editor. That remove trashes the attachment, so this gem enables Trashable on `RecordingStudioAttachable::Attachment`. Trashing the section still uses Trashable on the section.

## 0.9.0

Two-column kit editor and the Text section. Accessible is 0.10.

The kit URL now requires edit access and redirects to the editor. Hosts register section editors with `RecordingStudioPresskits.register_section_editor`.

Text is included. Add `"RecordingStudioPresskits::Text"` to `config.recordable_types`. Run `rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The new table is `recording_studio_texts` (`body`, `created_at`). `body` stores HTML from the FlatPack content editor. FlatPack's engine importmap pins TipTap. A host that skips that importmap has to pin the content preset itself. FakeBlock stays a dummy test double and stays off the add menu.

**+ Access** is on the kit editor only. Do not put it on the section editor, the index, the new form, or owner preview.

Bump `recording_studio_accessible` to `~> 0.10` (dummy tag `v0.10.0`). Run `bin/rails generate recording_studio_accessible:migrations`, then `bin/rails db:migrate`. 0.8.0 adds `depends_on_recording_id` on accesses. 0.10.0 adds access invitations. + Access links to the workspace manage-access page.

The Text section editor has no preview column. The kit editor and the public page still render the HTML. A custom editor hides its preview with `def self.preview?; false; end`. An editor that says nothing keeps two columns.

On the kit editor, the page heading is the kit name. There is no title form and no Save on that page. + Section is a primary button. Sections share one `FlatPack::List` inside one card, and the link text is the section type. The list uses `orderable: true` and `divider: true`. Remove is a trash icon. It posts delete, and the section controller calls `recording_studio_trashable_trash!`. Do not hard-delete the child. The preview column is a card. FlatPack list-orderable drags the rows. This pin's `saveOrder` does not run, so `list:reordered` posts `recording_id` and `before_recording_id` or `after_recording_id` to the kit order route, which calls `recording_studio_orderable_move!`. Pin the engine controller:

```ruby
pin_all_from RecordingStudioPresskits::Engine.root.join("app/javascript/recording_studio_presskits/controllers"), under: "controllers/recording_studio_presskits", to: "recording_studio_presskits/controllers"
```

## 0.8.0

Index and public page. Publishable is 0.3.

- Bump `recording_studio_publishable` to `~> 0.3` (dummy tag `v0.3.1`). Run its install and migrations generators if the host is still on 0.2.
- Kit show and kit edit use `render_publishable_quick_actions`. Do not render `EditButtonComponent` or a hand-rolled Go live button.
- `PressKit` sets `public_layout: "recording_studio_presskits/blank"`. Do not point it back at `recording_studio/default_layout`.
- View (`/published/:uuid/:slug`) and the publish-button Preview use that layout. No back, close, or TopNav.
- The owner Preview button stays on `recording_studio/default_layout`.

## 0.7.1

Cloud Agent Builds fetch Cursor skills at Build. Product is unchanged.

- No host or schema changes
- Rebuild the Cloud Agent environment with Draft off so Build loads the pack

## 0.7.0

The kit editor is a form plus an add dropdown. Default-layout chrome is page actions only.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Same gem pins as 0.6.0

### Host app

1. Creating a kit now lands on edit. Add, remove, and reorder return there too. Update any overridden redirects.
2. Replace the picker card with `RecordingStudioPresskits::PressKits::SectionDropdownComponent` (Flatpack `Button::Dropdown`). Types still come from `picker_types` / `allowed_parent_types`. If no types are registered, the control is a disabled Add a section button — no empty menu box.
3. On kit show and kit edit, use `render_publishable_quick_actions` for the publish control. On edit, keep **Add a section**, **Preview**, and that helper on one row. Do not render `EditButtonComponent`. Do not hand-roll a second publish control. Save stays normal size.
4. Keep test-only children off the dropdown with `config.excluded_picker_types`. Dummy excludes `FakeBlock`.
5. Put only page actions in `page_nav_right`. Access stays. Do not insert Sign in, Sign out, or Root Switchable into default layout. Core owns back and close.
6. On the kit index, keep **Presskit** with a Heroicons `plus` icon first and left. Switch cards vs table with icon-only `FlatPack::ButtonGroup::Component` (Flatpack's documented icon-only group). Do not put the create button on the right of the toggle. Do not invent a Press kits view-mode helper.
7. Logged-out public show stays default layout with back and close only.
8. Re-seed dummy if you still have Hero / Quotes / Notes children. Seed is Spring launch published and Autumn recap unpublished.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.6.0

Publish the kit, not each block. A live kit has a public page. An owner can preview a kit that is not live yet.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.0`)
- Orderable `~> 0.2` (dummy GitHub tag `0.2.0`)
- Trashable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Duplicatable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Publishable `~> 0.3` (dummy GitHub tag `v0.3.1`)
- FlatPack `>= 0.1.133` (dummy GitHub tag `v0.1.133`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it

### Host app

1. Add `recording_studio_publishable`, `~> 0.3`.
2. Run `bin/rails generate recording_studio_publishable:install` and the Publishable migrations generator.
3. Register `"RecordingStudioPublishable::Publishable"` next to `"RecordingStudioPresskits::PressKit"`.
4. Mount Publishable at `/` so live kits use `/published/:uuid/:slug`. Point `.to` `public_layout` at `recording_studio/default_layout`. Do not use Publishable's empty TopNav. Do not invent a press-kit public shell.
5. PressKit already enables Publishable with `.to` only (`public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`, `public_layout: "recording_studio/default_layout"`). The public controller includes `UsesDefaultLayout`. Do not use `.with`. Do not enable Publishable on section children.
6. Publish and unpublish through `RecordingStudioPublishable::Services::Publishables::Update` (or Publishable's management screens). Prefer `publishable_public_path`, `currently_published?`, `current_publishable`, `published?`, and `indexable?`.
7. Public lists use `PressKit.indexable`. Do not invent a second published query.
8. Admin now has live vs not-live widgets. Remove any host list-only / vanity-total widgets for kits.
9. Publishable's child uses Attachable for social cards. Add that gem in the host if Publishable cannot boot without it. Do not enable Attachable on PressKit.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.5.0

Authenticated press kit screens and one Admin list of live kits. This gem is still the container only.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.0`)
- Orderable `~> 0.2` (dummy GitHub tag `0.2.0`)
- Trashable `~> 0.4` (dummy GitHub tag `0.4.0`)
- Duplicatable `~> 0.4` (dummy GitHub tag `0.4.0`)
- FlatPack `>= 0.1.133` (dummy GitHub tag `v0.1.133`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it

### Host app

1. Add `recording_studio_admin`, `~> 2.0` and FlatPack `>= 0.1.133`.
2. Re-run `bin/rails generate recording_studio_presskits:install` (same generator, not a second identity).
3. Set `config.parent_root_type` to your host root class. Dummy stays `Workspace`.
4. Mount the user slice and point `/` at it, or redirect there.
5. Install Admin 2.0, mount it under an admin root, enable `section :press_kits`, and grant Accessible access on that root. Do not use `user.admin?`.
6. Register a component per child type with `register_section_component`. The container walks live children in order (`KitQuery.live_children`) and renders those components.
7. Keep writes on `record` / `revise` / `log_event!`. Query live kits with `recording_studio_trashable_active`.
8. Dummy puts Flatpack's built-in rounded theme on `<html data-theme="rounded">` via a host override of `recording_studio/default_layout`. Keep `UsesDefaultLayout`. Do not invent a custom theme.

Do not add Publishable, Attachable, or API in this slice.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

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
3. PressKit already enables Orderable, Trashable, and Duplicatable with `.to` only. Do not use `.with` or a second enablement path. Do not enable Orderable on PressKit children.
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
