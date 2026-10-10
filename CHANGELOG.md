# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.32.0] - 2026-10-10

### Added
- Live kits can be downloaded as a zip. PressKit opts into Downloadable `source: :manifest`, `format: :zip`, action `:"presskits.kit_download"`, export scope `:public`. The zip holds every placed photo (cover plus Images-section placements, original files, unique filenames) and a `kit.txt` of public kit copy only: title, short description, company, location, date, section titles/subtitles and public text, quotes with attribution, story/credits, and image caption/credit/alt. Drafts, unpublished revisions, trashed items, and private notes stay out.
- Presskits is the glue. On publish it calls `downloadable_generate!`. On unpublish it calls `downloadable_invalidate!(immediate: true)`. A revision to a live kit rebuilds. Downloadable's own debounce still covers ordinary content writes. Do not change Downloadable or Publishable for this.
- Default Accessible `action_audiences` for `:"presskits.kit_download"`: allowed `public` / `signed_in` / `granted`, default `granted`, granted roles `download` / `edit` / `admin` (not `view` alone). Hosts overwrite `config.action_audiences[:"presskits.kit_download"]`. `downloadable_available_for?` is true only while the kit is currently published.
- **Download kit** on the public kit page uses Downloadable's existing button helper (preparing / ready / retry). It is never on owner preview or the editor preview. A visitor who cannot see the full kit, or who lacks the download audience, does not see it.
- Depend on Downloadable `~> 0.3` (dummy tag `v0.3.0`), Accessible `~> 0.14` (dummy tag `v0.14.0`), and Publishable `~> 0.7` (dummy tag `v0.7.0`).
- Version `0.32.0`

### Upgrade notes
- Add Downloadable, bump Accessible to `~> 0.14` and Publishable to `~> 0.7`. Run Downloadable and Accessible install plus migrations (package identity columns, AccessConstraint / AccessRule). Mount Downloadable. Pin its Stimulus controllers. Rebuild Tailwind so Downloadable's button classes generate.
- PressKit already opts into Downloadable. Hosts overwrite the kit-download audience; they do not enable the mixin a second time. Accessible has `set_audience!` and `audience_options_for` but no kit-level audience picker — skip that UI until Accessible ships one.
- Flatpack has no download-control component at this pin. The public page uses Downloadable's `recording_studio_downloadable_button`. Do not invent a second preparing / ready / retry control.

## [0.31.0] - 2026-10-10

### Changed
- Images sections hold Attachable `Placement` children only. `LibraryPlacement.to` and Orderable `allows: Placement` replace direct `Attachable.to` on `RecordingStudioPresskits::Images`. Caption, credit, and alt stay on the library photo.
- **Add from library** is a `pk-editor` screen that reuses Attachable's picker Stimulus and JSON gallery (multi-select, `place_library_image`). **Upload** calls `upload_to_library_and_place`. A section refuses a second placement of the same photo. The same photo can sit in another section or kit.
- The section editor reuses Attachable's placements collection editor (list, slides, grid) for reorder and **Remove from here**. Public and preview resolve through `LibraryImages` (`Placements.resolve`), shared with the kit cover. Trashed or missing photos are skipped.
- Dummy Library sidebar adds **Images**, which opens the workspace library via `library_path_for`. Seeds place Harbour Gallery on a **Press photos** section as well as the cover.
- Hosts can set `config.section_library_keys` when upload should land in a named library. Default is `:default`.
- Version `0.31.0`

### Upgrade notes
- Rebuild seeds. Enable `LibraryPlacement.to` and Orderable for `Placement` on Images. Leave `Attachable.to` off the section. Quote still attaches one image directly. A host that already attached files under an Images section should move those photos into the workspace library and place them. Flatpack is unchanged (`>= 0.1.224`). Attachable's picker still wraps itself in a Modal and hardcodes single-select on its own placements screen — Presskits does not change Attachable. The kit editor picker is a screen in `pk-editor` instead.

## [0.30.0] - 2026-10-10

### Added
- Optional kit cover image from the root Attachable image library. Dummy Workspace enables `RecordingStudio::Capabilities::ImageLibrary.to`. PressKit enables `LibraryPlacement.to`. The first `place_library_image` result sits above the colour hero at `aspect-[1440/640]` with `object-cover`. Grid cards with a photo show the image and the title below it. Colour-only cards stay 9/16.
- Header **Cover image** and the kit FAB open Attachable's placements picker (`recording_placements_path`). No extra upload UI. Caption, credit, and alt stay on the library photo.
- Kit Orderable allows `RecordingStudioAttachable::Placement` as well as kit sections so `Placements.resolve` can see the cover. KitQuery and Reorder still list only sections. Section reorder keeps the placement on the kit.
- Dummy seeds a Harbour Gallery photo on Spring launch.
- `Cover::Image` owns hero and card photo helpers so Cover stays lean.
- Version `0.30.0`

### Upgrade notes
- Enable `ImageLibrary.to` on the host root and `LibraryPlacement.to` on PressKit. Keep Attachable library and placement types registered. Flatpack is `>= 0.1.224`. Flatpack has no full-bleed crop image, so the hero uses `aspect-[1440/640]` and a plain `image_tag`. Rebuild Tailwind so that aspect class generates.

## [0.29.0] - 2026-10-10

### Added
- Dummy Workspace opts into `RecordingStudio::Capabilities::Companies.to(allow: :one)`. The hero shows `RecordingStudioCompany.company(root)` with `recording_studio_company_logo` and the company name when that capability is on and a company exists. Hosts that skip the capability, or have no company, see no company row.
- PressKit opts into `RecordingStudio::Capabilities::Location.to`. One optional Location child on the kit (not a section, and not the Location section from later work) shows its icon and `display_name` under the company. Edit it on the existing header screen with `recording_studio_location_search_fields` (title, type, icon). Blank fields trash the place. Presskits enables Trashable on `RecordingStudio::Location::Location` so that clear works.
- Depend on `recording_studio_company` `~> 0.3` (dummy tag `v0.3.0`) and `recording_studio_location` `~> 0.4` (dummy tag `v0.5.1`).
- Dummy seeds **Harbour Studio** on Studio Workspace and **Harbour Gallery** on Spring launch.
- `KitLocation`, `Cover::Company`, and `HeaderAttributes` own lookup, write, and form parsing so Cover and the header controller stay lean.
- Version `0.29.0`

### Upgrade notes
- Add Company and Location, then run their install and migrations generators. Register `RecordingStudioCompany::Company` and `RecordingStudio::Location::Location`. Mount Company and Location. Enable `Companies.to(allow: :one)` on the host root if you want the company row. Rebuild Tailwind so Location search-field classes generate. Pin Location's Stimulus controllers. Flatpack `PageTitle` still has no byline slot for a logo-plus-name row, and `recording_studio_location_display` is a Card — the hero uses Avatar + Icon + text instead.

## [0.28.0] - 2026-10-10

### Changed
- The `:hero` cover no longer uses a fixed 21/9 band. Height comes from padding plus content: `p-12` on a phone and `md:p-24` (~96px) on a desktop. Grid `:card` and header-editor `:preview` stay 9/16.
- A muted **Press kit** eyebrow sits above the title (`recording_studio_presskits.cover.eyebrow`). Hosts override that i18n key. Size is `text-3xl` / `md:text-4xl` (~36px desktop). Colour is `color-mix` at 70% of the cover text colour. Flatpack `PageTitle` has no eyebrow slot, so this is a semantic `<p>` with those tokens.
- The hero no longer shows the kit short description. The field, column, header editor, API payload, and 9/16 cards keep it.
- Hero title is `FlatPack::PageTitle::Component` with `size: :display`, top-left, wrapping in `max-w-3xl`. Display uses `--display-size` (`clamp` 48px to 88px), `--display-leading` `1.05`, `--display-tracking` `-0.03em`, and `--display-weight` `600`. Flatpack is `>= 0.1.224` (dummy tag `v0.1.224`).
- Version `0.28.0`

### Upgrade notes
- Bump Flatpack to `>= 0.1.224` and rebuild Tailwind so `text-8xl` generates. Reload Flatpack CSS for the 88px `--display-size` clamp. Hosts that replaced `Cover::Component` at `:hero` should drop `aspect-[21/9]` / `min-h-64`, use `p-12 md:p-24`, render the i18n eyebrow above `PageTitle` `size: :display` (no subtitle on the band), and keep the short description on the header form and on cards.

## [0.27.0] - 2026-10-10

### Changed
- Kit editor sections and the kit header no longer put Edit heading, Edit content, or Add section in the page flow. The live preview matches the public kit: heading, then content.
- On a pointer that can hover, hover or focus-within tints the region with `--surface-muted-background-color` and shows the FAB. Keyboard focus uses `:focus-visible` only, and still reveals the FAB. On touch, the FAB is not always visible. A tap makes that section or the header the active region (tint and FAB). Tapping another region moves the active state. Tapping outside clears it. Flatpack has no tap-to-activate or hover-only visibility API, so `recording-studio-presskits--editor-chrome` owns the touch active state.
- The kit card is `padding: :none` with no inner section pad and no gap between sections. Each section owns `p-8 md:p-10 lg:p-12` (split as `pt`/`pb`/`px` so `pr-20` still clears the FAB). Vertical pad is the only space between sections. Phone padding stays `p-8`.
- Section hover and tap tint runs the full width of the kit, flush to the card sides, with `rounded-none`. The preview clips with `overflow-hidden` so the last section's tint follows the card's bottom radius.
- The `:hero` cover is a flush colour surface (no nested Card, `rounded-none`) that runs to the kit card's top and side edges. Title and description sit at the top (`justify-start`) with the existing `p-8 md:p-12` as the inset. Hero copy is `FlatPack::PageTitle::Component` with `size: :display` and the cover text colours, wrapped in `max-w-2xl`. Display uses `--display-size` (about 48px to 72px), `--display-tracking`, and `--display-leading`. The description keeps `fp-text-pretty`. The band stays 21/9 with `min-h-64`. `:card` and `:preview` stay 9/16 with title at the bottom.
- Header hover and tap use an inset overlay (`color-mix` black at 16%) instead of a surrounding muted tint, so the colour still bleeds to the card. The header FAB stays inside the cover with `offset: "1rem"` and `z-20`.
- The public kit uses the same unpadded card, flush hero, and section-owned pad.
- Each section has a contained Flatpack FAB (`size: :sm`, `icon: :plus`, `position: :top_right`, `backdrop: false`, `offset: "1rem"`, label **Section actions**). The region is `position: relative` so the FAB pins to that section; top corners open downward. Speed-dial: **Edit title** (shared heading screen in `pk-editor`), **Edit content**, **Reorder** (existing Reorder modal, fragment on this section), **Trash** (`style: :danger`, Trashable delete plus confirm), and **Add new section** (section picker, placed below this one).
- The kit header FAB is the same pattern: **Edit heading** and **Cover colours**, both opening the shared header screen. **Cover colours** lands on `#presskits-header-colours`.
- The toolbar **Section** button still adds at the end or into an empty kit.
- Palette **Colour** and **Text colour** on the kit header screen use `FlatPack::RadioGroup` `variant: :swatches` (`size: :md`). The option label is the accessible name and the tooltip. `:any` still uses `FlatPack::ColorSwatch`. Text colour **Auto** stays a separate inline radio with the same field name. Swatches need a CSS colour, and `auto` is not one.
- FlatPack is `>= 0.1.223` (dummy tag `v0.1.223`).
- The default cover palette swaps violet (`#7C3AED`) for sky (`#BFDBFE`). Dummy **Spring launch** uses sky with Auto text (dark). Stored violet still renders; hosts that want it as a swatch add it back.
- Dummy and gemspec pins take the newer tag from main and this branch: Recording Studio `v4.4.0`, Accessible `v0.13.0`, Admin `v2.1.0`, Attachable `v0.13.0`, Orderable `v0.2.7`, Trashable `v0.6.0`, Duplicatable `v0.4.5`, Publishable `v0.6.0`, External Embed `v0.1.4`, Video `v0.1.1`, Root Switchable `v0.6.0`, Metrics `v0.2.0`.
- Version `0.27.0`

### Upgrade notes
- Bump FlatPack to at least `0.1.223` and rebuild Tailwind so `text-6xl` / `text-7xl` and the swatch utilities generate. Reload Flatpack CSS for `--display-*` and `.fp-display`.
- Hosts that replaced `EditableSectionComponent` or `KitHeaderComponent` should render `FlatPack::Fab::Component` (`contained: true`, `position: :top_right`, `backdrop: false`, `size: :sm`, `icon: :plus`, `offset: "1rem"`) on a `position: relative` region. Sections own `p-8 md:p-10 lg:p-12` and `pr-20`, with `rounded-none` so the tint is flush to the card sides. The header region has no pad: the `:hero` cover bleeds to the card, and hover is an inset overlay rather than a surrounding muted tint. Hero copy sits at the top (`justify-start`) as `FlatPack::PageTitle::Component` with `size: :display` in a `max-w-2xl` block. The band stays 21/9 with `min-h-64`. Drop the in-flow ghost buttons, compact dropdown, custom hover outline, negative margins, and any kit-level section pad or gap. The kit card is `padding: :none`; the preview clips with `overflow-hidden`. The public kit uses the same unpadded card and section pad. Trash uses `with_action(..., style: :danger)`.
- FAB has no hover-only visibility or tap-to-activate API. Desktop hides the control with group-hover / focus-within. Touch uses `recording-studio-presskits--editor-chrome` and `data-pk-edit-active` so tint and FAB appear only on the tapped region.
- A host that replaced the shared header screen in `pk-editor` should render palette Colour and Text colour as `variant: :swatches`. Keep Auto as its own control. Keep ColorSwatch for `:any`.
- The default `cover_colors` list is now `#1F2937`, `#BFDBFE`, `#DB2777`, `#059669`, `#D97706`. A stored `#7C3AED` still paints. Add it back to the host palette if you still want that swatch.
- Bump Accessible to `~> 0.13`, Attachable to `~> 0.13`, Publishable to `~> 0.6`, and Trashable to `~> 0.6`. Run `bin/rails generate recording_studio_attachable:migrations` and `db:migrate` for the new library and placement tables. Add `RecordingStudioAttachable::Library` and `RecordingStudioAttachable::Placement` to `config.recordable_types`. Press kit Images still attach files under the section; moving to placements is a later host change.

## [0.26.1] - 2026-10-09

### Fixed
- Press kit metrics authorization resolves the admin root with
  `site_admin_recording_resolver`, then `access_recording_resolver`.
  If that resolver raises, `can_view?` denies access. The `:view` decision
  still goes through Accessible.

### Changed
- Version `0.26.1`

### Upgrade notes
- Bump to `0.26.1`. No migration.
- Site-wide metrics prefer `config.site_admin_recording_resolver`. A host that
  only sets `access_recording_resolver` still uses that fallback. If the
  fallback needs a controller, set the site resolver to the admin root so
  metrics discovery does not depend on one.
- A resolver error is treated as no access.

## [0.26.0] - 2026-10-09

Site-wide press kit metrics register with Recording Studio Metrics for the operations API.

### Added
- `RecordingStudioPresskits::Metrics.register!` registers a `:press_kits` resource
  (`blast_radius: :site`) with RecordingStudioMetrics. Metrics:
  `press_kits.total` (Live press kits), `press_kits.created_over_time` (Press kits
  created over time), and `press_kits.by_section_type` (sections across live kits
  by content type). Each is exposed on `:operations` only. Counts use
  `RecordingStudio::Recording` with `recordable_type` and `trashed_at: nil`.
  `api_authorize` uses `RecordingStudioPresskits::Api::Access.can_view?`
  (AdminRoot `:view`).
- Runtime dependency `recording_studio_metrics` `~> 0.2` (GitHub tag `v0.2.0`).
- `by_publish_status` is omitted. Publish state is not a column on PressKit or
  Recording; it lives on Publishable child records and needs `indexable` /
  `published` joins.

### Changed
- Version `0.26.0`

### Upgrade notes
- Bump to `0.26.0`. No migration.
- Add `recording_studio_metrics` at tag `v0.2.0`.
- This gem does not call `RecordingStudioMetrics::Api.register!`. The host
  registers Metrics endpoints once:

```ruby
RecordingStudioMetrics::Api.register!(api: :operations)
```

## [0.25.0] - 2026-10-09

Kit covers on the live kit editor from `0.24.0`.

### Added
- A press kit can store `cover_style`, `cover_color`, and `cover_text_color`. The only style is `color`. `nil` style means colour with the host default. `nil` text colour means Auto (WCAG contrast).
- Hosts set `cover_colors` to a palette (`%w[#1F2937 #7C3AED #DB2777 #059669 #D97706]` by default) or `:any`. `default_cover_color` is `#1F2937`. `cover_text_colors` defaults to `%w[#F8FAFC #111827 #E5E7EB #6B7280]` or `:any`. `cover_text_auto` (default true) adds an Auto choice.
- Writes must be a valid hex. In palette mode they must be one of those colours. A stored colour that later leaves the palette still renders.
- Overlay text uses `cover_text_color` when set. Auto picks light or dark from WCAG contrast. A low-contrast pair is allowed; the editor may hint.
- `RecordingStudioPresskits::Cover::Component` paints `:card` and `:preview` as 9/16 story tiles, and `:hero` as a wide 21/9 band. Title sits on the colour at the page-title size. A card description clamps to two lines.
- The shared kit header screen in `pk-editor` has **Colour** and **Text colour**. Each is a `FlatPack::RadioGroup` for a palette, or a `FlatPack::ColorSwatch` when the host allows any colour. Text colour includes **Auto**. A preview tile follows the colours as you edit. `0.27.0` paints those palette radios as swatches.
- The kit index cards, the kit header on the live editor, and the public kit use that component. Saving the header refreshes the editor hero through the existing Turbo Stream replace. Press Centers and hosts can render it too.
- When Recording Studio API is loaded, a press kit show and update include `cover_style`, `cover_color`, and `cover_text_color`. MCP uses the same payload. Duplicating a kit copies those fields.

### Changed
- Version `0.25.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_press_kits` gains nullable `cover_style`, `cover_color`, and `cover_text_color`. Existing kits keep their title and start on the default colour with Auto text.
- Reload the press kits JavaScript so the header preview follows Colour and Text colour. Importmap hosts that already pin Flatpack controllers load `flat-pack--color-swatch` with no new register call.
- Set `config.cover_colors`, `config.default_cover_color`, `config.cover_text_colors`, and `config.cover_text_auto` if the defaults are not your palette. Use `:any` to allow any hex.
- A host that replaced the kit index, the kit header, or the public page should render `RecordingStudioPresskits::Cover::Component`. A host that replaced the shared header screen in `pk-editor` adds Colour and Text colour.
- API clients that read a press kit now see `cover_style`, `cover_color`, and `cover_text_color`. Those keys are writable. Title and description stay on the header screen.

## [0.24.0] - 2026-10-09

### Changed
- The kit editor is the live kit, full width, inside one Flatpack Card. A slim toolbar holds **Section**, **Order**, and publish. The kit title and each section have a hover and focus outline, **Edit heading**, and (for sections) **Edit content**. Those editors open in a Flatpack Modal. Keyboard can reach the controls.
- Heading editing is one shared form for every section type. The modal title is **Section heading**. Title, Subtitle, then Update. Content editors no longer carry those fields. Public and preview headings go through `SectionHeadingComponent` and Flatpack `SectionTitle` (`size:`, `spacing:`, `level:`).
- **Section** opens a list of types. Each row has the type and a short line on why that block helps a press kit. Choosing one creates the section at once, with that type's label as the title, then stays on the kit. Orderable places it after the current section or at the end. The new block scrolls into view and highlights. A Flatpack toast offers **Undo**. Empty sections show an Add placeholder in the editor and stay off the public kit.
- Saves refresh the changed section behind the modal with Turbo streams and stay on the current screen. Save forms in `pk-editor` set `data-turbo-frame="_top"` so the navigable screen does not sit on loading. Child-item saves render `recording_studio_presskits/editor/preview_section`. **Order** opens **Reorder**. That list uses Flatpack `orderable_url` with `moving_recording_id` and `target_position`, and the kit order route calls `recording_studio_orderable_move!`.
- Heading, content, and child item screens share one navigable Flatpack Modal (`id: "pk-editor"`). Screens wrap in `flat_pack_modal_screen`. Drill-down uses `data-fp-nav="push"`. Back re-fetches the previous URL. Do not nest modals.
- FlatPack is `>= 0.1.216` (dummy tag `v0.1.216`).
- Version `0.24.0`

### Upgrade notes
- Bump FlatPack to at least `0.1.216` and reload its CSS and JavaScript. Navigable Modal is opt-in (`navigable: true`, `src:`). Hosts that replaced the split kit editor should render `KitEditorComponent` with that modal, `EditableSectionComponent`, and `GET sections/:id/heading` for the shared heading form. Editor openers use `data-modal-id="pk-editor"` and `data-turbo-frame="pk-editor-screen"`.
- Kit reorder posts `moving_recording_id` and `target_position` to the kit order route. That route calls `recording_studio_orderable_move!` and answers JSON `{ ok: true }` for the Flatpack list fetch. Neighbor ids and `ordered_recording_ids` still work.
- Flatpack has not shipped a save-complete event or unsaved-change protection yet. Preview updates use Turbo streams. Do not add a custom stack or an unsaved-close confirm.
- UI create sets the type label as the kit section title. `create_section!` still takes an optional title. Empty content is hidden on the public kit even when a heading is present.

## [0.23.0] - 2026-10-09

### Changed
- The press kit index uses a sidebar. **Library** is a collapsible group. **Credits** is the link under Library. The Credits button is gone from the kit list.
- The credits list subtitle is "People, companies and organisations that you credit in Press kits". **+ Credit** is only as wide as its label. The table shows the name.
- On a credit, **Save** sits under the fields and is only as wide as its label. **Trash** shares that line, sits on the right, and uses the danger style.
- Version `0.23.0`

### Upgrade notes
- Hosts that linked people to a Credits button beside Presskit should use the Library group in the sidebar instead. The credits table no longer shows usual role or URL. Those fields stay on the credit form.

## [0.22.1] - 2026-10-08

### Fixed
- The dummy default layout was drawing two back chevrons. PageNav always draws a history back button, and the layout also turned the screen's back URL into `secondary_anchor_href`, which uses the same chevron. The layout now draws one back control. A screen that sets a back URL gets that link. A screen that does not gets PageNav's history button. Close stays on `anchor_href`.

### Changed
- Version `0.22.1`

### Upgrade notes
- If a host copied the dummy default layout and assigns `page_nav_back_url` to `secondary_anchor_href`, remove that assignment. Render one back control from the layout. Keep close on `anchor_href`.

## [0.22.0] - 2026-10-08

Facts & Figures.

### Added
- A Facts & Figures section can be added to a press kit. `RecordingStudioPresskits::FactsSection` sits under the kit section and stores `display_style` (`list`, `cards`, or `table`) and `columns` (`2`, `3`, or `4`, for cards). Each `RecordingStudioPresskits::Fact` is a child recording with a required label and value, plus optional unit, description, source URL, and as-of date.
- The section editor keeps Title and Subtitle on the Section title tab. Content holds Show as, Columns when Cards is selected, **+ Fact**, and the fact list. A blank section shows an empty state. Facts are added, edited, reordered, and trashed like quotes.
- List, cards, and table layouts render on the preview and the public page. Cards use the saved column count on larger screens and collapse on smaller ones. A blank section does not leave an empty preview card. A blank kit section title falls back to Facts & Figures.
- When Recording Studio API is loaded, a facts section includes `display` and ordered `facts`. Trashed facts stay out of that payload. MCP uses the same structured data.

### Changed
- Version `0.22.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. That adds `recording_studio_facts_sections` and `recording_studio_facts`.
- Add `RecordingStudioPresskits::FactsSection` and `RecordingStudioPresskits::Fact` to `recordable_types`.
- Create the section with `RecordingStudioPresskits.create_section!` and `content_type: "RecordingStudioPresskits::FactsSection"`. Record facts under the facts section. Save display settings with `revise` on that section. Reorder facts through Orderable on the facts section.

## [0.21.0] - 2026-10-08

Credits.

### Added
- A credit is reusable information for a person or studio in the current workspace. It stores a name, an optional URL, and an optional usual role. The new credit modal labels that field **Default role**. The stored name stays `usual_role`.
- Credits has its own list, create, edit, and trash screens. Trash and restore use Trashable. Restoring a credit puts it back on kits that already listed it.
- A Credits section can be added to a press kit. Each line stores the role and the order for that kit, and points at the credit. Removing a line leaves the credit in the workspace.
- The same credit can be used on more than one kit, with a different role on each line. Changing the usual role does not change lines that already exist.
- A Credits section keeps Title and Subtitle on the Section title tab. On Content, a collection editor searches workspace credits, creates one from a modal, and sets **Role on this kit** on each line. **Save** sits under that table. It starts in the default style and turns primary when the rows no longer match the saved lines. The preview column follows a chosen credit, a role edit, a removed row, and a saved reorder before the page reloads. An empty credits section does not show a preview card.
- The public page and the kit preview show the role, the name, and a link when the credit has a URL.
- When Recording Studio API is loaded, a credit exposes index, show, create, and update. A credits section exposes `add_credit` and `reorder_credits`. A credit line exposes index, show, update, and `remove_credit`.
- Version `0.21.0`

### Changed
- FlatPack is `>= 0.1.204` (dummy tag `v0.1.204`).

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. That adds `recording_studio_credits`, `recording_studio_credits_sections`, and `recording_studio_credit_lines`.
- Add `RecordingStudioPresskits::Credit`, `RecordingStudioPresskits::CreditsSection`, and `RecordingStudioPresskits::CreditLine` to `recordable_types`.
- Add a credit with `RecordingStudioPresskits::Credits.create!`. Add one to a section with `RecordingStudioPresskits::Credits.add!`. Do not copy the name or URL onto the line.
- Bump FlatPack to at least `0.1.204`. Reload its CSS and JavaScript. `style:` on FlatPack tabs is a button style name. Press kits do not pass a CSS string there. Select wrappers also include `flat-pack-input-wrapper`. The credits section uses `FlatPack::CollectionEditor::Component`. Importmap hosts that already pin Flatpack controllers load `flat-pack--collection-editor` and `flat-pack--list-orderable` with no new register call. Reload the press kits JavaScript too. The credits preview follows a chosen credit, a role edit, and a removed row without waiting for Save. **Save** on that form is under the table, `style: :default`, and the `flat-pack--unsaved-changes` submit target. It turns primary when the rows change.

## [0.20.0] - 2026-10-07

Video section.

### Added
- A press kit can add a Video section. Press Kits owns the section. Recording Studio Video owns each video recording. External Embed owns provider embeds. YouTube ships with External Embed. Other providers appear when the host registers them. Press Kits does not register Vimeo.
- `RecordingStudioPresskits::VideoSection` is an empty recordable under the kit section. It includes Trashable and Videos. It does not include Orderable. Videos stay in the order they were added. + Video sits on the Content tab and opens a new video. The form uses Video's fields. A saved video shows Video's player.
- The kit section payload keeps `title`, `subtitle`, `content_type`, and `content_id`. A video section also includes `videos`. Each video has `title`, `url`, `description`, `provider`, `canonical_url`, and `content_type`.
- New table `recording_studio_video_sections`.
- Version `0.20.0`

### Changed
- The section editor keeps its preview column. The card is rendered only when `SectionFrameComponent` would show a title, a subtitle, or content. Text, Images, Quotes, and Video return false from `render?` when they have nothing to show. The kit editor uses the same check, so a blank section does not leave an empty preview card.
- Every section editor uses `FlatPack::Tabs::Component` with `variant: :pills` and `style: :default`. The tabs are Content and Section title. Content is selected first. Section title is Title, Subtitle, and Update under those fields. There is no Heading group.
- A blank kit section title falls back to the content type label on the preview, the public page, and the page nav. The saved title stays blank. The Title field shows that label as its placeholder. A saved title replaces the fallback. The fallback does not show the preview card by itself.
- Kit section rows use the section menu icon in the list icon slot. Header and section rows use `class: "!items-center"`. Drag to reorder still uses the orderable list.
- A text section with a saved title shows that title in the kit list. A blank text title stays Text. The label truncates to the column. Images, Quotes, Video, and host types stay on the content type label.
- Text Body saves from Content, with its own Update under the field. Images, Quotes, and Video keep their editors on Content, outside the title form.
- FlatPack is `>= 0.1.202` (dummy tag `v0.1.202`).

### Upgrade notes
- Add `recording_studio_video`, `~> 0.1.0` (tag `v0.1.0`) and `recording_studio_external_embed`, `~> 0.1.1` (tag `v0.1.3`).
- Bump FlatPack to at least `0.1.202` (tag `v0.1.202`). A host that replaced the kit section row should pass the section menu icon and `class: "!items-center"` on `FlatPack::List::Item`. Do not put `arrows-up-down` in that slot. Show a text section's saved title as that row's label, truncate the label, and leave other types on the content type label. A host that replaced `SectionFrameComponent` renders `RecordingStudioPresskits.section_heading` for the visible title. Keep the preview card off until there is a saved title, a subtitle, or content. `default_section_heading` is the Title placeholder. A host that replaced `SectionEditorComponent` renders pill tabs (`variant: :pills`, `style: :default`) labeled Content and Section title. Put Title, Subtitle, and Update on Section title, with Update under the fields. Remove any Heading fieldset. Put the content editor on Content. An editor with `self.below?` stays outside the title form. An editor without it, such as Text, gets its own form and Update on Content. Keep the unsaved-changes controller on each of those forms, and keep Update as `style: :default` with the submit target. `style:` on tabs is a button style name. A CSS string raises `ArgumentError`.
- Add `RecordingStudioPresskits::VideoSection` and `RecordingStudioVideo::Video` to `recordable_types`.
- Run `bin/rails generate recording_studio_video:install`, `bin/rails generate recording_studio_video:migrations`, and `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. External Embed has no table. See `MIGRATION_NOTES.md`.

## [0.19.0] - 2026-10-07

Section heading save button.

### Changed
- FlatPack is `>= 0.1.200` (dummy tag `v0.1.200`).
- The section heading form uses Flatpack unsaved changes. Update renders `style: :default` and is that form's submit target. It stays default while Title, Subtitle, and any other fields in the form match the saved values, and turns primary when they differ. Restoring those values returns it to default.
- Version `0.19.0`

### Upgrade notes
- Bump FlatPack to at least `0.1.200`. Importmap hosts that already pin Flatpack controllers load `flat-pack--unsaved-changes` with no new register call. A bundled app that copies the esbuild list in Flatpack's installation doc registers `UnsavedChangesController` as `flat-pack--unsaved-changes`.
- Reload Flatpack CSS and JavaScript. FlatPack `0.1.199` also changes orderable list drag and makes list rows slightly taller. Call sites stay the same. Rebuild host Tailwind so the new list spacing utilities exist.
- Hosts that replaced `SectionEditorComponent` add `data: { controller: "flat-pack--unsaved-changes" }` on the heading form and mark Update with `style: :default` and `data: { "flat-pack--unsaved-changes-target": "submit" }`.
- Header Update and a quote's Save stay primary. They do not use this controller.

## [0.18.0] - 2026-10-07

Section editor form.

### Changed
- Every section editor uses one heading form. Update sits above Title, Subtitle, and any extra fields, in the same place on Text, Images, and Quotes.
- A content editor renders inside that form, under Update, unless it defines `self.below?` and returns true. Text leaves that unset, so Body stays in the form. Images and Quotes return true. Their UI sits under the form: Upload and the photo editor for Images, + Quote and the quote list for Quotes.
- `form?` is gone.
- Version `0.18.0`

### Upgrade notes
- Remove `form?` from a content editor. If that editor cannot live inside the heading form, define `self.below?` and return true. The shell still renders `section_actions`, then that editor, under Update, Title, and Subtitle.

## [0.17.0] - 2026-10-06

Kit sections.

### Changed
- A press kit's ordered children are kit sections. Each kit section has an optional title and subtitle, and one content recording under it. Text keeps its body. Images keep their attachments. A quote section stays the parent of its quotes, and the quote section sits under the kit section.
- `register_section` registers a content type for the + Section menu, plus its component, editor, and optional `prepare` hook. `section?` is true only for a kit section.
- The kit editor, the preview, and the public page walk kit sections. `SectionFrameComponent` renders the kit section title and subtitle, then the content component.
- Reordering or removing a section targets the kit section. Duplicating a kit copies each kit section and the content under it.
- When Recording Studio API is loaded, `create_section` and `reorder_sections` are press kit actions, and `remove_section` is a kit section action. They call `create_section!`, `recording_studio_orderable_reorder!`, and `recording_studio_trashable_trash!`.
- The kit editor Header row uses Heroicon `bars-3-bottom-left`. Section rows keep `arrows-up-down`. Header still cannot be reordered or removed.
- Every section editor uses one two-column template. Column one holds Title, Subtitle, the section buttons, and that section's editor. Column two is the preview. Text shows that preview too. `preview?` on a content editor no longer changes the page.
- Section editors no longer show Cancel. Back still returns to the kit. The quote edit screen and the header screen still have Cancel.
- Version `0.17.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. The migration is irreversible. It wraps legacy press-kit children in kit sections, copies their order, and drops the text title column and the images title and subtitle columns. A migrated quote section gets the kit section title Quotes. See `MIGRATION_NOTES.md`.
- Add `RecordingStudioPresskits::KitSection` to `recordable_types`. Point content `allowed_parent_types` at `RecordingStudioPresskits::KitSection`.
- Create sections with `RecordingStudioPresskits.create_section!`. API clients use the press kit action `create_section`, reorder with `reorder_sections`, and remove a kit section with `remove_section`. There is still no generic kit section create or destroy.
- The Header row icon is `bars-3-bottom-left`. Hosts do not configure it.
- Section editors are always two columns. Remove `preview?` from a content editor. It no longer hides the preview.
- Section editors no longer show Cancel. Back still returns to the kit.

## [0.16.0] - 2026-10-06

Images section heading.

### Changed
- An images section has an optional title and subtitle instead of a section caption. A blank one is stored as nothing. The editor shows Title and Subtitle, each with its name, in column one. Column two is a preview of that section inside a FlatPack card, with no card header. The kit row stays Images. The kit preview and the public page show the title with FlatPack's section title and its anchor, and the subtitle under that title, when the title is set. Each photo still has its own caption, credit, and alt text.
- A kit section is a type registered with `register_section`. Declaring the press kit as a parent does not make a recording a section. The editor, the preview, and the public page show registered sections. Other children stay under the kit. Reordering a section leaves those other children in place.
- Version `0.16.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_images` drops `caption` and gains nullable `title` and `subtitle`. An existing section caption is copied into `title`. Subtitle starts empty. Photo captions stay on the attachment.
- Register each host section with `RecordingStudioPresskits.register_section`. Keep `allowed_parent_types` so the recording can live under the kit. `excluded_picker_types` only hides a registered section from + Section.

## [0.15.0] - 2026-10-06

Kit header.

### Added
- A press kit has an optional short description, 280 characters at most. A blank one is stored as nothing. The kit editor lists Header with the sections. That row opens a screen for the title and short description. The screen is a two-column grid: the fields, then a preview. The row cannot be removed or reordered. The kit preview, the public page, and owner preview show the description under the title when it is present.

### Changed
- Renaming a kit moves from `PATCH press_kits/:id` to `PATCH press_kits/:press_kit_id/header`, which also saves the short description.
- Version `0.15.0`
- FlatPack is `>= 0.1.198` (dummy tag `v0.1.198`).
- Point host and dummy Gemfiles at Recording Studio `v4.2.2`
- Point sibling Recording Studio gems at current tags: Accessible `v0.11.1`, Admin `v2.0.4`, Attachable `v0.7.1`, Duplicatable `v0.4.3`, Orderable `v0.2.5`, Publishable `v0.4.2`, Trashable `v0.4.4`, and dummy Root Switchable `v0.5.3`.
- Gemspec constraints: Accessible `~> 0.11`, Publishable `~> 0.4`
- Dummy Accessible roles are strings (`view` / `edit` / `admin`). Grants still go through `bootstrap_owner_access!` / `grant_access`. Accessible 0.8–0.11 migrations are in `test/dummy`.
- Gem tests keep a tiny `Object#stub` helper because Minitest 6 dropped `minitest/mock`.

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_press_kits` gains a nullable `description`. Existing kits keep their title and start with no description. If the dummy database was migrated on 0.14.0, this also restores `20261006120000` (text section title) so migrate and rollback can see that file.
- Bump FlatPack to at least `0.1.198`. Link `stylesheet_link_tag "flat_pack/application"` beside `flat_pack/variables` on host layouts. That sheet paints primary buttons. The public blank layout already links it.
- Bump `recording_studio_accessible` to `~> 0.11` and run `bin/rails generate recording_studio_accessible:migrations`. Access `role` becomes a string.
- Bump `recording_studio_publishable` to `~> 0.4`.
- Pin Admin, Attachable, Duplicatable, Orderable, Trashable, and Root Switchable to the tags above.

## [0.14.0] - 2026-10-06

Text section title.

### Added
- A text section has an optional title. A blank one is stored as nothing. The text editor shows Title and Body, each with its name. The kit preview and the public page show that title with FlatPack's section title and its anchor when it is set. The kit row stays Text.

### Changed
- + Section menu items show a Heroicon beside Text, Images, and Quotes.
- Version `0.14.0`

### Upgrade notes
- Run `bin/rails generate recording_studio_presskits:migrations` and `bin/rails db:migrate`. `recording_studio_texts` gains a nullable `title`. Existing text sections start with no title. The title is no longer taken from the first line of the body.

## [0.13.0] - 2026-10-02

Images editor.

### Changed
- The Images editor edits each photo with Attachable's `attachment_collection_editor`: caption, credit, and alt text, then Save. Trash on a photo returns to the section. The section caption and the Upload button stay.
- Attachable is `~> 0.7` (dummy tag `v0.7.0`). FlatPack is `>= 0.1.135` (dummy tag `v0.1.135`).
- Version `0.13.0`

### Upgrade notes
- Bump `recording_studio_attachable` to `~> 0.7` and FlatPack to at least `0.1.135`.
- Run `bin/rails generate recording_studio_attachable:migrations` and `bin/rails db:migrate`. Attachment rows gain `root_recording_id`, `caption`, `credit`, and `alt_text`.

## [0.12.0] - 2026-10-02

Quote display.

### Changed
- A quote row shows the quote, truncated to the column, with the name on the line below.
- The quotes action is + Quote: a Heroicons plus icon and the label Quote.
- Column two, the kit preview, and the public page render each quote with FlatPack's quote component at large size. The citation is the name, role, and organisation.
- Version `0.12.0`

### Upgrade notes
- No host or schema changes

## [0.11.0] - 2026-10-02

Quotes section.

### Added
- `RecordingStudioPresskits::QuoteSection` is a press kit section. Each quote is a child recording with body, name, and optional role and organisation. The section editor is an orderable list in column one, and column two previews the saved quotes. Add quote and Cancel sit above that grid. Each quote has its own edit screen. Orderable is on the quote section. Attachable is on the quote for one image. A blank body stays off the preview and the public page.

### Changed
- Version `0.11.0`

### Upgrade notes
- Add `"RecordingStudioPresskits::QuoteSection"` and `"RecordingStudioPresskits::Quote"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`

## [0.10.0] - 2026-10-01

Images section. Attachable is 0.4.

### Added
- `RecordingStudioPresskits::Images` is a press kit section. The field is an optional `caption`. Photos are Attachable image attachments on that section, so one section holds many images. Attachable stays off PressKit. The editor uploads from an Upload button after Cancel.

### Changed
- Version `0.10.0`
- The Images editor no longer shows a drag-and-drop upload area.

### Upgrade notes
- Add `"RecordingStudioPresskits::Images"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`
- Depend on `recording_studio_attachable`, `~> 0.4`, mount that engine, and wire Active Storage direct uploads

## [0.9.0] - 2026-10-01

Two-column kit editor and the Text section. Accessible is 0.10.

### Added
- `RecordingStudioPresskits::Text` is a press kit section. The field is `body`. Hosts add the class to `recordable_types` and run the migrations generator.

### Changed
- Version `0.9.0`
- The kit URL requires edit access and redirects to a two-column editor. Hosts register section editors with `register_section_editor`. Text registers its own editor.
- On the kit editor, the page heading is the kit name. + Section and the publish control share one row above the two-column grid. + Section is first and uses the primary button. The label is Section with a Heroicons plus icon. The title form and Save are gone from this page.
- Each section's remove control is a trash icon. Destroy calls `recording_studio_trashable_trash!`.
- Kit sections share one list inside one card. The link is the section type. The preview column is one card.
- Section order uses FlatPack list `orderable: true` and `divider: true`. The `arrows-up-down` icon stays in the list icon slot. This FlatPack pin does not persist the drop, so `list:reordered` calls `recording_studio_orderable_move!`. Move up and Move down are gone. Hosts pin `controllers/recording_studio_presskits` from the engine JavaScript.
- The Text field is FlatPack's content WYSIWYG. The kit editor and the public page render the saved HTML. A new Text section opens with a heading, a paragraph, and a list. The section editor has no Remove button.
- **+ Access** is on the kit editor only. The index, the new form, the section editor, and owner preview leave the page-nav right slot empty.
- Accessible is `~> 0.10` (dummy tag `v0.10.0`). + Access is a FlatPack link (`href:`) to manage access.
- A section editor shows the type as a page heading. Update and Cancel sit above the grid. Cancel uses the default button and returns to the kit. The default layout is two columns, with the preview in a card lined up with the field. The text field has no label of its own. Text hides that preview and uses one full-width column. An editor opts out by defining `preview?` and returning false.

### Upgrade notes
- Add `"RecordingStudioPresskits::Text"` to `recordable_types` and run `rails generate recording_studio_presskits:migrations`
- Bump `recording_studio_accessible` to `~> 0.10` and run its migrations generator
- Pin `controllers/recording_studio_presskits` so a section drop can save

## [0.8.0] - 2026-10-01

Index and public page. Publishable is 0.3.

### Added
- Kit cards show a 16/9 cover. A recordable can supply `cover_image_url`. A missing or unsafe URL uses the muted card color and a photo icon

### Changed
- Version `0.8.0`
- Index primary action is **Presskit** with a Heroicons `plus` icon. It stays first and left, ahead of the cards / table toggle
- Index page title is **My presskits**
- Publishable is `~> 0.3` (dummy tag `v0.3.1`). Kit show and kit edit use `render_publishable_quick_actions` for the publish control
- Public kit view uses `recording_studio_presskits/blank`. View and the publish-button Preview render the kit with no page nav. Owner preview stays on `recording_studio/default_layout`

### Upgrade notes
- Bump `recording_studio_publishable` to `~> 0.3`
- Public kits use `recording_studio_presskits/blank`. Do not point `public_layout` back at `recording_studio/default_layout`

## [0.7.1] - 2026-09-03

Cloud Agent Builds fetch Cursor skills at Build. Product is unchanged.

### Added
- Cloud Agent boot files: `.cursor/environment.json`, `.cursor/install.sh`, `.cursor/fetch-skills.sh`, and `.cursor/start.sh`
- [Cursor skills in Cloud Agents](docs/cursor-skills.md)
- Tests for the install hook warm skip, skippable provision, and dummy boot files

### Changed
- Version `0.7.1`
- `.cursor/install.sh` skips apt, ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are already usable. A skippable provision failure does not fail the Build. Fetch-skills always runs last

### Upgrade notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft off so Build loads the pack

## [0.7.0] - 2026-08-22

The kit editor is a form and one action row. Chrome on default-layout screens is page actions only. Dummy seed stays two kits and no fake sections.

### Added
- Kit edit screen with the kit title form and a Flatpack **Add a section** dropdown under the title
- The same row holds Preview and Publishable's **Draft / Published** action (`EditButtonComponent`)
- `excluded_picker_types` so hosts can keep test-only children off the dropdown
- Dummy excludes `FakeBlock` from the dropdown. FakeBlock stays for tests only

### Changed
- Version `0.7.0`
- Creating a kit lands on edit
- Add, remove, and reorder return to edit
- Default-layout page-nav right slot is Access only (`recording_studio_accessible_avatars`). Sign out and Root Switchable stay out of that slot, dummy extra nav, and gem views that use default layout
- Logged-out public show stays default layout with back and close only. No Sign in
- Owner preview can show Access. No Sign out or Root Switchable
- Dummy seed: **Spring launch** published, **Autumn recap** unpublished, no seeded fake sections
- Kit edit Save stays normal size (`items-start`). Empty kits skip the empty-state tray. An add dropdown with no types is a disabled button, not an empty menu hole
- Index toolbar is left-justified: **New press kit** first, then icon-only `FlatPack::ButtonGroup::Component` for cards vs table (`squares-2x2` / `table-cells`). No Cards / Table labels. No Press kits helper. This Flatpack pin's SegmentedButtons is text-only.

### Removed
- The "Add a section" picker card and radio list
- Dummy `presskits_extra_nav` Sign out control

### Upgrade notes
- Point create / add / remove / reorder at `edit_press_kit_path` if you overrode those redirects
- Replace any host copy of the picker card with `SectionDropdownComponent` (Flatpack Button Dropdown)
- Do not put Sign in, Sign out, or Root Switchable into `page_nav_right` or `recording_studio/default_layout`. Core owns back and close. Access stays in the slot
- Keep **New press kit** first and left on the index. Cards vs table is icon-only `FlatPack::ButtonGroup::Component`. Do not invent a Press kits toggle
- If a dummy or test type should stay off the add dropdown, set `config.excluded_picker_types`
- Re-seed dummy to drop leftover Hero / Quotes / Notes children

## [0.6.0] - 2026-08-21

Publish the kit, not each block. A live kit is readable without signing in. An owner can preview a kit that is not live yet. Admin shows live vs not-live work. Nothing is in production — this breaks in place.

### Added
- Publishable on `RecordingStudioPresskits::PressKit` via `.to` only (`public_controller: "recording_studio_presskits/public_press_kits"`, `public_action: :show`, `public_layout: "recording_studio/default_layout"`)
- Public show that walks children in order and renders each type's public component. The container does not style the blocks. Logged-out public show uses Recording Studio's default layout (`UsesDefaultLayout`), not Publishable's empty TopNav
- Owner preview of a kit that is not live, on Recording Studio's default layout
- Admin widgets for live kits (`PressKit.indexable`) and kits that are not live yet. Still no vanity total
- Dummy seed publishes **Spring launch** and leaves **Autumn recap** unpublished
- Dummy mounts Publishable at `/` and registers `RecordingStudioPublishable::Publishable`

### Changed
- Version `0.6.0`
- Gemspec adds `recording_studio_publishable`, `~> 0.2`
- Dummy GitHub tag adds Publishable `v0.2.0`
- Picker uses declared parent types so Publishable's capability child stays off the list
- `KitQuery.live_children` skips the Publishable child

### Upgrade notes
- Add `recording_studio_publishable`, `~> 0.2` (dummy GitHub tag `v0.2.0`)
- Run `bin/rails generate recording_studio_publishable:install` and `bin/rails generate recording_studio_publishable:migrations`
- Register `"RecordingStudioPublishable::Publishable"` in `RecordingStudio.configure`
- Mount `RecordingStudioPublishable::Engine` at `/` (or keep the path Publishable's README uses)
- PressKit already includes Publishable via `.to` only, with `public_layout: "recording_studio/default_layout"`. Do not use `.with`. Do not enable Publishable on FakeBlock or later section children. Do not use Publishable's public layout as the public shell
- Use `PressKit.indexable` / `indexable?` for public lists. Publish and unpublish through Publishable's services
- Replace any host list-only Admin widget with the live / not-live widgets this gem now registers
- Publishable's child recordable uses Attachable for social cards. Dummy pins Attachable `0.4.0` so that child can boot. Do not enable Attachable on PressKit

## [0.5.0] - 2026-08-21

Authenticated press kit screens and a staff list of live kits. This gem is still the container only — later addons are the sections. No public page and no publish.

### Added
- Mountable user slice: index of the current root's kits, kit editor, picker add, remove, and reorder
- Cards and table views of the same kit list, switched with `FlatPack::SegmentedButtons::Component`
- Reusable ViewComponents for index, kit show, child rows, and the section picker
- Empty index and empty kit states
- Admin section `press_kits` with one list widget of live kits (`recording_studio_admin`, `~> 2.0`)
- Install generator writes `parent_root_type` and enables `section :press_kits` when an AdminRoot model exists
- Dummy Admin root, Admin mount, and Accessible bootstrap so the seeded admin user can open the list
- Dummy `FakeBlock::Component` so the kit page can render host children without styling them

### Changed
- Version `0.5.0`
- Gemspec adds `recording_studio_admin`, `~> 2.0` and `flat_pack`, `>= 0.1.133`
- Dummy GitHub tags add Recording Studio Admin `2.0.0`
- PressKit `allowed_parent_types` uses `RecordingStudioPresskits.parent_root_type` (default `"Workspace"`)
- Dummy `/` redirects to the mounted press kit index
- Dummy app name is "Press kits"
- Dummy overrides Recording Studio's default layout so `<html data-theme="rounded">` wraps index, kit show, and Admin. That is Flatpack's built-in rounded theme from `flat_pack/variables`. Authenticated screens still use `UsesDefaultLayout`.
- Dummy PageNav maps core's `page_nav_anchor_url` slot to Flatpack 0.1.133 `anchor_href` and `anchor_tooltip` so the close X renders next to back on index, kit show, and new.

### Removed
- Dummy "Dummy host" landing page and workspace outline tree

### Upgrade notes
- Add `recording_studio_admin`, `~> 2.0` and FlatPack `>= 0.1.133`
- Run `bin/rails generate recording_studio_presskits:install` again (or mount the engine and copy the new initializer keys)
- Set `config.parent_root_type` to your host root class. Dummy stays `Workspace`
- Mount the user slice and point `/` at it, or redirect there
- Install Admin 2.0, create an admin root, enable `section :press_kits`, and grant Accessible access on that root
- Register a component per child type with `register_section_component`. Dummy registers `FakeBlock::Component`
- Do not enable Publishable, Attachable, or API in this slice

## [0.4.0] - 2026-08-21

Press kits can be ordered, trashed, restored, and duplicated. This gem is still the container only — no editor, no public page, no publish.

### Added
- `recording_studio_orderable`, `~> 0.2`, `recording_studio_trashable`, `~> 0.4`, and `recording_studio_duplicatable`, `~> 0.4`
- Orderable on `RecordingStudioPresskits::PressKit` with no `allows:` so every direct child type can sort
- Trashable on `RecordingStudioPresskits::PressKit`
- Duplicatable on `RecordingStudioPresskits::PressKit` with suffix `" (Copy)"` and `exclude_children: []` so FakeBlock and later section children copy with the kit
- Dummy `FakeBlock` enables Trashable so remove is testable without a real addon
- Dummy `Workspace` enables Orderable with `allows: ["RecordingStudioPresskits::PressKit"]` so kits under the root can be reordered in tests
- Dummy seed for a second fake section (`Quotes`) so reorder is obvious
- Dummy mounts and migrations for Orderable and Trashable (Duplicatable has no engine-owned schema)

### Changed
- Dummy GitHub tags add Orderable `0.2.0`, Trashable `0.4.0`, and Duplicatable `0.4.0`
- Dummy home lists active recordings in Orderable position order

### Upgrade notes
- Add `recording_studio_orderable`, `recording_studio_trashable`, and `recording_studio_duplicatable` next to this gem
- Run each mixin's install generator and Orderable/Trashable migrations
- PressKit already includes the three mixins via `.to` only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path. Do not enable Orderable on PressKit children. Do not enable Duplicatable on FakeBlock — child copy is a parent filter, not a child opt-in.
- Duplicatable's README takes `include_children` as an array of types, not `true`. This gem uses `exclude_children: []` so every direct child type is copied.
- Reorder, trash, restore, purge, and duplicate through the mixin APIs. Prefer `recording_studio_trashable_active` over a new host `default_scope`.
- Accessible grants on the workspace root still cover kits. Mixin writes authorize through Accessible.
- Do not enable Publishable, Attachable, or API in this slice

## [0.3.0] - 2026-08-21

First product release of Recording Studio Press Kits. A press kit is the container under a host root. Later addons supply the sections. Publish the kit, not each block.

### Added
- `RecordingStudioPresskits::PressKit` nested recordable under the host root (`Workspace` in dummy)
- Title on the kit snapshot table `recording_studio_press_kits`
- `RecordingStudioPresskits.picker_types` lists host types that allow PressKit as a parent
- Dummy host-only `FakeBlock` so add/remove is testable without a real section addon
- Dummy seed for one press kit and one fake section
- Dummy authenticated home shows that seeded outline (host sandbox, not a product editor)
- Dummy Tailwind `@source` paths that actually find FlatPack and Recording Studio gems, so default layout CSS loads
- Dummy `rake tailwind:bundle_sources` writes those gem paths before each Tailwind build
- Gemspec dependencies `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`

### Changed
- Renamed the engine from the addon template to `recording_studio_presskits`
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.1`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`

### Removed
- Leftover template identity in the public README and gemspec
- Dummy starter docs pages
- Template example capability mixin
- Engine sample home controller

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.0` and Accessible `v0.6.1`
- Declare `spec.add_dependency "recording_studio", "~> 4.2"` and `spec.add_dependency "recording_studio_accessible", "~> 0.6"`
- Register `"RecordingStudioPresskits::PressKit"` in `RecordingStudio.configure`
- Later section addons must use `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Core 4.2 has no public type-name alias.
- Core `record` defaults the parent to the workspace root. Nest a section with `parent_recording: kit_recording`.
- Install engine migrations and keep writes on `record` / `revise` / `log_event!`
- Do not enable Publishable, Orderable, Trashable, Duplicatable, Attachable, or API in this slice

## [0.2.0] - 2026-08-21

Addon starting point on Recording Studio 4.x, before this repo became Press Kits.

### Added
- Gemspec dependency `recording_studio`, `~> 4.1`
- Dummy host wiring for Accessible (`enable_capability(:accessible, on: Workspace)`)
- `bin/rename_gem` leftover-identity rewrite/verification for README, homepage, and changelog URLs

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated layout is Recording Studio's default layout plus FlatPack CSS/JS; Devise keeps its own sign-in layout
- Dummy app security pins: Rails `8.1.3.1`, `json` `2.21.2`, `mail` `2.9.1`, Brakeman `8.0.6`
- Require `RecordingStudio::Hooks` and `RecordingStudio::Services::BaseService` from core instead of shipping copies

### Removed
- Copied Hooks and BaseService files
- Product-shipped example service
- Custom `flat_pack_sidebar` authenticated shell

### Upgrade notes
- Point dummy or host Gemfiles at Recording Studio `v4.2.0` (not `recording_studio/v3.0.0`)
- Add `spec.add_dependency "recording_studio", "~> 4.1"` to addon gemspecs
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Delete any copied Hooks or BaseService files and require the core classes
- Keep recordable declarations; they are required
- If Accessible is bundled, call `RecordingStudio.enable_capability(:accessible, on: Workspace)` (or your root type)

## [0.1.2] - 2026-07-21

### Changed
- Bumped the dummy app FlatPack dependency from `v0.1.33` to `v0.1.129`

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `v0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.29.0...HEAD
[0.29.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.28.0...v0.29.0
[0.28.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.27.0...v0.28.0
[0.27.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.26.1...v0.27.0
[0.26.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.26.0...v0.26.1
[0.26.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.25.0...v0.26.0
[0.25.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.24.0...v0.25.0
[0.24.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.23.0...v0.24.0
[0.23.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.22.1...v0.23.0
[0.22.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.22.0...v0.22.1
[0.22.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.21.0...v0.22.0
[0.21.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.20.0...v0.21.0
[0.20.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.19.0...v0.20.0
[0.19.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.18.0...v0.19.0
[0.18.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.17.0...v0.18.0
[0.17.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.15.0...v0.16.0
[0.15.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.13.0
[0.12.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.12.0
[0.11.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.11.0
[0.10.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.10.0
[0.9.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.9.0
[0.8.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.8.0
[0.7.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.7.1
[0.7.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.7.0
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_presskits/releases/tag/v0.1.0
