# Upgrade notes

## 0.55.0

Bump to `0.55.0`. Run `bin/rails generate recording_studio_presskits:migrations`, then `bin/rails db:migrate`. The new migration adds a nullable `release_date` date column on `recording_studio_press_kits`. There is no backfill. Existing kits keep a blank date, and the card hides the line. Flatpack stays `>= 0.1.235`.

Rebuild Tailwind so `@min-[640px]:flex`, `flex-wrap`, `gap-x-4`, `gap-y-1.5`, `w-full`, and `@min-[640px]:w-auto` generate.

Hosts that replaced the header editor should add `FlatPack::DateInput` named `press_kit[release_date]`. The kit location is still the Location child (`KitLocation`), not a string column. On a cover at least 640px wide, the date and that place share one wrapping muted line under the description. Each shows only when it is present. Both blank hides the line. Below 640px the date stays off and the place stays on its own line.

`Cover::Component` no longer paints **View** from `href`. Pass buttons with `with_action` (`renders_many :actions`). An empty slot hides the row. The public page no longer renders `recording_studio_downloadable_button` under the header. **Download kit** on the cover links to `recording_package_path` when that route exists, otherwise the first images section. It shows when `KitDownload.allowed?`. **Contact** shows for a Press contact credit or a section titled Contact. The index passes **View**. The header does not. **View** is that same primary FlatPack button (`size: :lg`, `arrow-right`), with the button's own radius.

Below 640px of the cover container, hide the subtitle and the short description (`hidden`, then `@min-[640px]:block` on the subtitle and `@min-[640px]:line-clamp-3` on the description). The editor inline fields use the same hide. Wide cards still show both. Rebuild Tailwind so those two utilities generate.

## 0.54.0

No presskits migration. Pin `recording_studio_trashable` to `~> 0.9` (tag `v0.9.0`). Pin `recording_studio_video` to `~> 0.2.0` (tag `v0.2.0`).

Where main used `where(trashed_at: nil)`, use `where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)` on the same relation (section `child_recordings` finders, Metrics `relation`). That ANDs with a host `default_scope` the same way main’s filter did.

Where main already used `recording_studio_trashable_active` — credits `live_credits`, `KitQuery.live_kits`, and the kit-query `merge(active)` child helpers — keep `_active`. Do not rewrite those to `kept_sql`; `_active` unscopes `trashed_at` first and that is main’s behavior for those sites.

Kept/trashed checks use `recording_studio_trashable_kept?` and `recording_studio_trashable_trashed?`. User trash and restore stay on `recording_studio_trashable_trash!` / `recording_studio_trashable_restore!`.

`LegacySectionTree` still copies `trashed_at` and `trash_root` with `update!` during the one-time section-tree upgrade. Do not switch that path to `RecordingStudioTrashable.void_recording!` — void writes through `update_columns`, does not set `trash_root`, and would change restore/trash-bin behavior for upgraded trees.

## 0.53.0

No migration. Bump to `0.53.0`. Flatpack stays `>= 0.1.235`. Rebuild Tailwind so Media and Overlay utilities generate, including `rounded-[var(--media-radius)]`, `outline-[var(--media-outline-color)]`, `group/media`, and the overlay inset classes.

`JPG · width×height · ratio` is a `FlatPack::Badge` (`size: :xs`) at `placement: :bottom_left`, `inset: :sm` on `FlatPack::Media::Component`. The line under the photo is the attachment name. `ImageFacts#caption` is gone. Use `name` and `meta`.

## 0.52.0

No migration. Bump to `0.52.0`. Flatpack stays `>= 0.1.235`.

On the public kit and the owner preview, the text heading slot (`data-presskits-text-copy-slot`) renders `FlatPack::CopyButton`: **Copy text**, `style: :secondary` (outlined, flat), `size: :sm`, icon `clipboard-document`. The clipboard string is `Text.clipboard_text`, the full plain body with a blank line between paragraphs. **Show more** only clamps the visible HTML. The kit editor does not render the button.

`TextSectionHeadingComponent` reads the text body itself. Pass `clipboard_text:` to use a different string. An empty string leaves the slot empty. The `flat_pack/clipboard` and `flat_pack/copy` pins are the same ones `0.50.0` already requires for **Copy credits**.

## 0.51.0

Bump to `0.51.0`. Flatpack is `>= 0.1.235` (dummy tag `v0.1.235`). Rebuild Tailwind. Reload Press Kits JavaScript. The copy-link controller is `recording-studio-presskits--copy-link`.

`FlatPack::SectionTitle` `with_trailing` is where a count badge sits, after the heading and outside the copy-link anchor. The public video heading passes `FlatPack::Badge` (`size: :sm`) with the number of videos. A section with no videos does not render, so the badge is absent then. The editor still edits the title with `FlatPack::InlineEdit` and does not show the count. Text sections keep `TextSectionHeadingComponent`. Images keep their own count badge.

Flatpack 0.1.235 removes `FlatPack::Masonry::Image`. The images gallery still uses `FlatPack::Masonry::Component`. Each photo is `FlatPack::Media::Component` inside `with_item`. The caption is host text under the picture: attachment name, then `JPG · width×height · ratio`. Hosts that copied `with_image` should switch to that.

`recording_studio_videos` gains `duration_seconds` (integer) and `thumbnail_url` (text). Those columns belong to Recording Studio Video's table. Press Kits adds them here because duration and the thumbnail override are part of the video snapshot, and `revise` already copies that row. A second recording would split the snapshot. Run the Video gem's migrations first so the table exists, then:

```bash
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

The editor asks for length as `m:ss` (`1:24`) and stores seconds. A blank length is allowed. The thumbnail field is an optional http or https override. When it is blank, YouTube uses `https://i.ytimg.com/vi/{id}/hqdefault.jpg`. Vimeo uses `https://vimeo.com/api/oembed.json` and caches the thumbnail. Press Kits still does not call `RecordingStudio::ExternalEmbed.register`. Vimeo works after the host registers that provider.

`VideoSection` includes Orderable for `RecordingStudioVideo::Video`. `active_videos` follows that order. A video with no position yet sorts after positioned ones, then by `created_at`. The public page features the first and puts the rest in `FlatPack::Grid` `cols: 2`. The card uses `FlatPack::VideoPreview`: poster, centred play control, and `recording_studio_video_player` inside `with_player` so the iframe stays in a template until play. **Copy link** dispatches `toast:add`. Below `sm` it is icon-only, with `aria-label` and a tooltip of **Copy link**. From `sm` up the label is visible. The title wraps on the same row. The public card does not show a watch-on-provider link or the description. The public heading shows the video count in the trailing slot.

The video payload adds `duration_seconds` and `thumbnail_url`. `thumbnail_url` is the poster the card would show, not only the override. The kit text file adds a `Provider · m:ss` line between the title and the URL.

## 0.50.0

Run the new migration. It adds `icon` (string, optional) on `recording_studio_credit_lines`. There is no backfill and no compatibility shim. Existing lines stay without an icon until an editor picks one.

Bump to `0.50.0`. Flatpack is `>= 0.1.234` (dummy tag `v0.1.234`). Rebuild Tailwind so the credits grid utilities generate (`grid-cols-1`, `md:grid-cols-2`, `lg:grid-cols-4` come from `FlatPack::Grid`).

**Copy credits** is `FlatPack::CopyButton` on the public credits heading. A host that pins Flatpack scripts by hand needs:

```ruby
pin "flat_pack/clipboard", to: "flat_pack/clipboard.js", preload: false
pin "flat_pack/copy", to: "flat_pack/copy.js", preload: false
```

Flatpack's engine importmap already includes both. Section title anchors use the same clipboard controller.

The public credits section is a four-column grid (two from `md`, one on a phone). The role is uppercase. The name is bold. A URL adds `arrow-up-right`. An icon is optional and comes from `CreditIcons`. If any visible line has one, the others keep an empty icon-sized space. If none do, the plain layout is used. An empty section stays hidden.

`Credits.add!` and `Credits.revise_line!` take `icon:`. `Credits.revise_role!` still changes only the role and keeps the icon. The line API accepts `icon` on show, update, and `add_credit`. A blank or unknown icon is stored as nil and left out of the payload.

## 0.49.0

No migration. Bump to `0.49.0`. Rebuild Tailwind so `@min-[640px]:pt-16`, `@min-[640px]:top-18`, `@min-[640px]:hidden`, `@min-[640px]:contents`, and `pr-16` generate. Flatpack stays `>= 0.1.233`.

On a cover card whose container is at least 640px wide, the company name, title, subtitle, list heart, and description sit lower. The body still has `pt-7`. The copy adds `pt-16`, so the company name starts about 6rem from the top of the card. A narrower card keeps only the body's `pt-7`.

**View** stays in the footer with `mt-auto`. **Edit image** stays on the cover overlay.

On the kit editor, **Edit** is out of the copy row. Below 640px of container width it sits on the cover overlay, in the same top-right item as **Edit image** and immediately to its left (`gap-2`). From 640px that copy is hidden, and **Edit** is the body overlay item (`placement: :top_right`, `inset: :lg`). Only one is shown. The copy keeps the body's `pt-7` below 640px, and adds `@min-[640px]:pt-16` from 640px.

The list heart is also out of the copy. It is `with_item(placement: :top_right, inset: :sm)` on the body overlay. The company line has `pr-16`. Title, subtitle, description, and location stay full width. From 640px, `@min-[640px]:top-18` moves the heart down to the company line, under **Edit**.

## 0.48.0

No migration. Rebuild Tailwind so the text-section utilities generate.

On the public kit and the owner preview, a text section heading is `TextSectionHeadingComponent`: bold, `text-[2rem]`, `--surface-content-color`, with an empty `data-presskits-text-copy-slot` on the right. Do not put a copy button there yet. Other section types still render `SectionTitle` with its anchor, including the Images count badge and **Download all images**. Section cards stay `rounded-[var(--radius-lg)]` (1.5rem / 24px).

The public text body uses `--surface-muted-content-color`, `text-base`, `leading-7`, and `max-w-[65ch]`. It does not use `.ProseMirror`. Copy longer than 700 characters clamps to eight lines (`max-h-[14rem]`) with a fade and **Show more** / **Show less** (`aria-expanded`). That control is `FlatPack::Button` `style: :default`. Shorter copy has no toggle. The kit editor always shows the full body and still edits it with `FlatPack::InlineEdit` `mode: :rich` (the bubble toolbar). A text section's editor title uses the same bold classes. Other sections stay semibold `text-2xl`.

`FlatPack::Collapse` hides a whole region behind a title. It is not this clamp.

Hosts that replaced `SectionFrameComponent` should render `TextSectionHeadingComponent` for a text section and leave the copy slot empty. Images sections still use the download row and the count badge.

## 0.47.0

No migration. Bump to `0.47.0`. Flatpack is `>= 0.1.233` (dummy tag `v0.1.233`). Rebuild Tailwind so the masonry column classes (`columns-1`, `md:columns-2`, `lg:columns-4`) and the Section Title trailing-row utilities (`flex-wrap`, `flex-1`, `max-w-max`, `break-words`, `shrink-0`) are generated.

The public Images section uses `FlatPack::Masonry::Component` (`order: :columns`) and `FlatPack::Masonry::Image`. Photos keep their natural ratio. The first 12 render. **Show more images (N)** replaces the gallery Turbo frame (`presskits-images-<id>`) with the rest. N is the number of photos in the section.

The public Images heading passes a `FlatPack::Badge` (`size: :sm`, text is the photo count) through `FlatPack::SectionTitle` `with_trailing`. The badge is outside the heading and outside the copy-link anchor. The editor still edits the title with `FlatPack::InlineEdit`. `SectionTitle` `title:` is a string, and Inline Edit has no trailing slot, so the count badge stays off the editor.

**Download all images** is on the public heading row. It zips that section's photos only, from `GET /recording_studio_presskits/image_archives/:id` (the images content recording). The kit zip still includes the cover, every images section, and `kit.txt`. The section zip is sent only when `Visibility.presentation_for` is `:full`.

Width and height are not columns. `ImagePixelSize` writes them onto the blob metadata for JPEG and PNG when ActiveStorage's analyzer left them out. The caption is one `FlatPack::Masonry::Image` `caption:` string: attachment name, then `JPG · width×height · ratio`. That component paints the whole string in muted `text-sm`. A primary title and a smaller meta line need `meta:` on `FlatPack::Masonry::Image`. Presskits does not restyle the figcaption.

## 0.46.0

No migration. Link `stylesheet_link_tag "recording_studio_presskits/brand_buttons"` on every layout that renders a kit, next to `flat_pack/application`. That sheet paints the pressed fill of a primary button from `--button-primary-active-background-color`. Without it, hover and the focus ring still follow the brand, and the pressed fill stays on Flatpack's hover.

`RecordingStudioPresskits.branding_style_for` now also sets `--color-primary-active`, `--button-primary-active-background-color`, and `--button-primary-active-border-color`. Hover and the pressed fill use `oklch(from var(--color-primary) …)` on the wrapper, so they follow the kit colour instead of the theme root.

The same string is on `#presskits-editor-preview` (header card and section cards), `#presskits-owner-preview`, and the audience preview's `#presskits-public-preview`. `#presskits-public-page` and `#presskits-kit-embed` stay. It still never goes on `<html>`.

Editor chrome stays on Flatpack. Toolbar, page nav, the header form, and tabs are outside those wrappers. Section edit, order, and remove, the empty-section action, header **Edit**, and **Edit image** use `presskits-neutral-controls`, which puts Flatpack's primary tokens back.

Bump Flatpack to `>= 0.1.231` and rebuild Tailwind. The cover uses `FlatPack::Overlay`: the photo is `with_media`, and the **Press kit** badge is `with_item(placement: :top_left, inset: :md)` with `FlatPack::Badge` `style: :default`. On the editor card, **Edit image** is `with_item(placement: :top_right, inset: :md)`. Overlay only places those pieces. The badge follows `--badge-default-background-color` and `--badge-default-text-color` (muted surface `#e5e5e5` and `#333` on the rounded theme). It does not follow the brand, and Presskits does not override those colours. **View** and other primary buttons still use the brand.

## 0.45.0

No migration.

On the kit editor, the cover card edits the kit title, subtitle, and short description in place with `FlatPack::InlineEdit::Component` (`mode: :text`). Hover shows the words can be edited. Click edits them in place. An empty title shows **Add a title**. An empty save is blocked on the card and the stored title stays. An empty subtitle shows **Add a subtitle**. An empty short description shows **Add a short description** and stays clickable. Each save PATCHes `press_kit[title]`, `press_kit[subtitle]`, or `press_kit[description]` on the header update path. A request that includes only one of those leaves the others, and leaves `brand_color`, `font_family`, and the kit location.

The header screen is kit location, **Brand**, and **Cover image**. The header plus FAB is gone. Hover shows **Edit** at the top right of the card body. It opens that screen. **Edit image** sits in the cover's top bar, opposite the **Press kit** badge, and opens `#press_kit_cover_image`. Below `sm`, and on touch, both stay visible and show only their icons. They are `EditorActionButtonComponent`, the same Flatpack button (`size: :sm`) as a section's **Edit** and **Order**. `Cover::Component` takes those as `body_actions` and `image_actions`. Index cards, the public kit, and the owner preview do not pass `inline_path` or those slots, so they keep the static title, subtitle, and clamped short description, with the badge alone in the cover's top bar.

Hosts that replaced `KitHeaderComponent` should drop the FAB and pass those two slots on the editor card only.

On every cover card, the kit location sits under the short description. A blank short description puts it under the title and subtitle. The limited preview leaves the short description off, so location sits under the title and subtitle there. A Location section is unchanged: those places stay inside the section, not on the card.

## 0.44.0

No press kit migration. Embargo rows belong to `recording_studio_embargo` 0.1.0.

This repo vendors that gem at `vendor/gems/recording_studio_embargo` (tag `v0.1.0`, commit `8d1e787`) and loads it with `path:`. Switch the Gemfile to `git: "https://github.com/bowerbird-app/RecordingStudio_embargo.git", tag: "v0.1.0"` once CI can reach the private repo. Hosts run `bin/rails generate recording_studio_embargo:migrations` and `bin/rails db:migrate`. That creates `recording_studio_embargo_embargoes` and a partial unique index so a recording has one live embargo child. Mount `RecordingStudioEmbargo::Engine`.

Press kits include `RecordingStudio::Capabilities::Embargo.to` for `presskits.kit_view_full` and `presskits.kit_download`. `RecordingStudioEmbargo.restriction_for` returns `:allow`, `:deny`, or `:not_applicable`. Publishable still wins for a kit that is not live. `:deny` uses the kit's visibility fallback (`preview` or `hidden`) and blocks package generate, fetch, and status through `downloadable_available_for?`. Downloadable already calls that hook from `Authorization.allowed?` after the standing audience check, on show, create, and status, so that gem does not need a code change. A signed Active Storage URL that was already issued stays valid until it expires. `:not_applicable` after `lifts_at` needs no job.

Early access is one switch on the embargo gem. It allows an actor who already satisfies Accessible's `:granted` audience for that action. Download's granted roles stay `download`, `edit`, and `admin`, so a view grant does not include the zip. The toolbar uses `render_embargo_button`. The editor is the gem's screen. Override `recording_studio_embargo.editor.subtitle`, `enable_help`, and `early_access_help` to change its copy. The public **Embargoed** badge stays in `recording_studio_presskits.embargo`. Copying a kit runs `RecordingStudioEmbargo.attributes_for_duplicate`, which clears the window.

## 0.43.0

Run the new migration. It drops `cover_style`, `cover_color`, and `cover_text_color` from `recording_studio_press_kits` and adds nullable `brand_color` and `font_family`. Nothing is copied across. A kit that should keep a colour needs `brand_color` written again.

```bash
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

Remove `cover_colors`, `default_cover_color`, `cover_text_colors`, and `cover_text_auto` from the initializer and from `config/recording_studio_presskits.yml`.

`brand_color` is `#RRGGBB` or nil. `font_family` is `sans`, `serif`, `mono`, or nil. Nil means inherit. `KitBranding` resolves each field on its own: the kit value, then `RecordingStudioPressCenters.branding_for` when that gem is loaded, then `#333333` and `sans`. Saving `sans` or `#333333` on the **Custom** tab keeps that value. It does not collapse back to nil. The **Press center** tab stores both fields as nil. Without press centers, the header form shows the swatches and stores both values.

`RecordingStudioPresskits.branding_style_for(kit_recording)` always returns a style string. With `RecordingStudioPressCenters::Branding` loaded, that string is `Branding.new(brand_color:, font_family:).style_attribute`. Without it, `BrandStyle` emits the same tokens: `--color-primary`, `--color-primary-text`, the primary button tokens, the ring tokens, and `font-family`. The published page puts it on `#presskits-public-page`. A host embed puts it on `#presskits-kit-embed`. It never goes on `<html>` or on the kit editor.

`Cover::Component` only has `:card`. `:hero` and `:preview` render that card. The card keeps the wide container-query layout from 0.40.0. It is the header on the public page, the owner preview, the audience preview, and the kit editor. Sections stay in `SectionCardComponent`. The pill and **View** use the resolved brand, with contrast text. A missing photo is a muted surface. The short description is on the card. The company row is the name. The kit location sits under it. The header form does not render a second preview of the card.

The header screen uses `FlatPack::Tabs` (**Press center** and **Custom**) when press centers is loaded. **Custom** shows `FlatPack::FontSwatch` and `FlatPack::ColorSwatch` on one line, prefilled with the resolved press center values. Those tabs stay off when the constant is missing.

API show and update keys are `title`, `description`, `brand_color`, and `font_family`. Duplicating a kit copies the brand columns.

## 0.42.0

No migration. Bump Flatpack to `>= 0.1.228` (dummy tag `v0.1.228`) and reload its CSS and JavaScript. Rebuild Tailwind so inline-edit and trash-button classes generate. Link `stylesheet_link_tag "flat_pack/inline_edit"` on the kit editor layout, next to `flat_pack/application`. Propshaft fingerprints that file, and the `@import` inside `flat_pack/application` does not resolve it. Without the link, the empty-subtitle placeholder and the hover cue do not paint.

On the kit editor, section title and subtitle are `FlatPack::InlineEdit::Component` with `mode: :text`. Hover shows they can be edited. Click edits in place. An empty subtitle shows **Add a subtitle**. Each save PATCHes `kit_section[title]` or `kit_section[subtitle]` on the section. A request that includes only one of those leaves the other stored value.

`TrashButton` focuses its arm when it connects. The kit editor stops that focus from scrolling the page, then blurs it, so the editor opens at the top and the action row stays hidden until hover.

The section plus FAB is gone. There is no per-section **Add new section**. The toolbar **Section** control is the only add. Hover (or focus) shows **Edit**, **Order**, and an icon-only `FlatPack::TrashButton::Component` (`size: :sm`, `expand: :left`). A text section skips **Edit**. **Edit** opens the content screen for images, credits, quotes, facts, video, and location. It does not edit the title or subtitle. **Order** opens the existing Reorder modal. Trash deletes with Trashable. The button's own confirm animation is the only confirm. `:sm` is the same size as the labeled buttons. The editor clears `--hit-target-min` on that control so the icon-only box is not floored at 2.75rem. Below `sm`, and on touch (`hover: none`), the row stays visible. Below `sm` the row sits above the title and lines up with the top-right corner of the section. **Edit** and **Order** show only their icons at that width. Each keeps `aria-label`, and the label span is `sr-only`. They do not use `icon_only:`, which would add `fp-hit-target` and grow them to 2.75rem. From `sm` up they stay labeled and sit beside the title. A section does not paint a hover background. Focus and a touch tap still use the muted tint.

A text section hides **Edit**. Its body is inline edit with `mode: :rich` (the bubble toolbar) and saves `text[body]` on that same section path. The public kit and the owner preview still use `SectionTitle`.

`EditableSectionComponent` now takes `section_recording`, `content_path`, `remove_path`, and `highlight`. `KitEditorComponent` no longer takes `heading_path`. The heading screen is still there for a direct visit.

## 0.41.0

No migration. Each section is a Flatpack card (`SectionCardComponent`) on the kit editor, the public kit, and the owner preview. The card is white and rounded, with the same soft shadow as the editor header (`shadow-[0px_12px_40px_0px_rgba(26,20,10,0.08)]`). `gap-6` separates the header from each section, and each section from the next. Padding inside a section stays `pt-8 pb-8 px-8`, then `md:pt-10`, then `lg:pt-12`.

The public hero and the limited-preview hero stay in their own card. The limited preview's explanation sits in a section card under that hero. Download stays on the hero card. Section menus, the reorder list, and trash are unchanged.

## 0.40.0

No migration and no new card content. `:card` now switches on its own width, not the viewport.

`Cover::Component` at `:card` is a container (`@container`). Below 640px it stays the stacked grid card: cover or colour on top (`aspect-[430/368]`), **Press kit** pill, company and heart, title, subtitle, description, and **View** at the bottom when `href` is set. At 640px and wider, the same elements sit in a row. The cover is the left half, full height, at least as tall as it is wide (`min-h-[50cqw]`). The pill stays on the cover. The body is the right half. The company row and heart stay at the top. **View** uses `mt-auto`, so it stays at the bottom right.

The kit editor header renders that same `:card` with no `href` and `heading: :h1`, so the wide row replaces the colour hero on the edit page and the kit name stays the page heading. Index cards stay `h2`. **Edit heading**, **Cover colours**, and **Cover image** stay on the header FAB. The short description shows in the card body. Kit location stays on the public `:hero` and on the header form. Section editing is unchanged. `:hero` stays on the public kit and owner preview. `:preview` stays the 9/16 tile on the header screen.

Rebuild Tailwind so the container-query utilities generate. Tailwind 4 includes `@container`. A host on an older Tailwind needs a small scoped `@container (min-width: 640px)` rule with the same layout. A grid cell narrower than 640px keeps the stacked card.

## 0.39.0

No migration and no new gem. Press kits still does not depend on press centers.

When `RecordingStudioPressCenters` is loaded, `RecordingStudioPresskits.branding_style_for(kit_recording)` returns `RecordingStudioPressCenters.branding_for(kit_recording)&.style_attribute`. A missing constant, or nil branding, leaves the Flatpack theme as it is.

The published page puts that string on `#presskits-public-page`, around the full kit and the audience preview. It does not go on `<html>`. A host embed of `PublicShowComponent` puts the same string on `#presskits-kit-embed`. The published page passes `branding: false` so the two wrappers are not nested. Owner preview passes `branding: false`. The kit editor does not use either wrapper.

Cover tiles keep their own `cover_color` and `cover_text_color`. The brand is not written onto the kit. Flatpack defines the primary button tokens and the ring tokens on the theme root, so the press center string redeclares those tokens, plus `--color-primary`, `--color-primary-text`, `--color-primary-hover`, and `font-family`, on the wrapper.

## 0.38.1

No migration and no config change. The visibility screen in `pk-editor` keeps one heading: PageTitle **Visibility**. The small chrome title is blank, the same way Downloads does it. **Update** has `mt-4` above it.

Audience is an inline RadioGroup. Anyone uses `globe-alt`, Signed in uses `user`, People with access uses `lock-closed`, and a custom audience uses `user-group`. **Who can view the full press kit?** stays on the page for screen readers (`sr-only`) and is not shown.

Hosts that copied `app/views/recording_studio_presskits/visibilities/edit.html.erb` should pass `presskits_editor_blank_chrome_title` into `flat_pack_modal_screen` and keep the PageTitle. The Update row stays `#presskits-visibility-actions`. Hosts that replaced the visibility editor should use that RadioGroup and the `sr-only` label.

## 0.38.0

Press kits gain an optional `subtitle` column. Blank lines become nil. The limit is 120 characters.

```bash
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

`Cover::Component` at `:card` is the grid card for a press center. The top is the cover photo (`object-cover`, rounded top corners) or the cover colour when the kit has no photo. A **Press kit** pill sits on that image. The white body is a flex column. The company name (from `Cover::Company`, hidden when the root has no company) sits 14px above the title. The heart stays on that company row. The subtitle and the short description, clamped to three lines, follow. **View** links to `href` and uses `mt-auto`, so it stays at the bottom of a card that fills its grid cell. Host grids should use `align: :stretch`. Its background is `resolved_cover_color`, or the default cover colour. The label uses `Cover::Contrast.text_on`.

The heart is Lists' `recording_studio_add_to_list` (`icon: "heart"`, `size: :lg`, `show_chevron: false`). It renders when Lists is loaded, the card has a recording, and `Current.actor` is present. The card is not itself a link, and the heart stops the click, so it does not open the kit. A press kit page still renders when Lists is not loaded.

`:preview` stays a 9/16 colour tile and skips the photo. A subtitle, when present, is the preview line under the title, and the short description sits under that. `:hero` keeps the eyebrow, the display title, the company, and the location. The subtitle sits under the title. The short description stays off the hero.

The header screen saves subtitle with the title and the short description. `Api::PressKitPayload` includes `subtitle`.

## 0.37.0

Press kits now depend on Lists `~> 0.5` (dummy tag `v0.5.0`). Installing the gem does not add list controls to a press kit.

```bash
bin/rails generate recording_studio_lists:install --mount-path /
bin/rails generate recording_studio_lists:migrations
bin/rails db:migrate
```

Register `"RecordingStudio::Lists::List"` and `"RecordingStudio::Lists::ListItem"`. Enable `:lists` on the host root:

```ruby
RecordingStudio.enable_capability(:lists, on: Workspace)
```

Mount `RecordingStudioLists::Engine` at `/` after the host routes. `/` stays the host home. The screens are `/lists`, `/lists/new`, and `/lists/:id`. The lists install generator's default mount is `/recording_studio_lists`. Pass `--mount-path /`. Say no to the optional `config/recording_studio_lists.yml` prompt. The engine pins its add-to-list Stimulus controller. Rebuild Tailwind so the lists screens are included. This dummy writes that scan from `rake tailwind:bundle_sources`.

## 0.36.1

No migration, no config change, and no new public method. The README section **Displaying press kits in a host** documents the card, the full kit, the audience preview, `KitQuery.for_root`, and `Visibility.presentation_for`. Those calls already exist on `0.36.0`.

## 0.36.0

Images and the kit cover no longer use the Attachable image library. There is no schema change in Press Kits and no data migration. Recording Studio is not in production. Reseed the dummy app, or upload the photos again.

`RecordingStudioPresskits::Images` includes `Attachable.to` for many `image/*` files and `Orderable.to(allows: ["RecordingStudioAttachable::Attachment"])`. Caption, credit, and alt are columns on each attachment. **Upload** is Attachable's file button (`attachment_file_buttons/button`) and keeps importing another file. The collection editor saves, reorders, and trashes those attachments.

PressKit includes `Attachable.to` with `max_file_count: 1` for the cover photo. Cover colour stays on the kit. Upload and remove sit outside the header save form. `CoverImage` and the public gallery, hero, cards, and zip read `DirectImages`.

Duplicating a kit copies each attachment onto a new blob through `AttachmentCopy`. The attachment `name` still gains Duplicatable's ` (Copy)` suffix. `original_filename` does not.

Drop `LibraryPlacement.to` from PressKit and Images. Drop `config.section_library_keys`. Drop `ImageLibrary.to` from the host root when nothing else needs a workspace image library. Keep Attachable installed. Keep `Attachment`, `Library`, and `Placement` registered. Those tables belong to Attachable. Credits stay a library.

`RecordingStudio::Capabilities::PressKits` from 0.35.0 stays. Include it on a recordable that should hold press kits. Leave PressKit `allowed_parent_types` as the host root.

## 0.35.0

Include `RecordingStudio::Capabilities::PressKits.to` on a recordable that should hold press kits. `.to` takes no options. The gem registers `:press_kits` at boot with PressKit as its child recordable. Core adds that recordable to the kit's allowed parents. Leave `allowed_parent_types` on PressKit as the host root only. Do not add a second parent list.

A capability-owned kit cannot sit under a shared root. Workspace is not a shared root, so a kit recorded directly on the workspace still belongs there.

`KitQuery.for_root` returns every live kit under that root. The index, the editor, and the owner preview use that query.

## 0.34.0

A Location section is a kit section whose content is `RecordingStudioPresskits::LocationSection`. That type is an empty table: a UUID primary key and `created_at`. Places are `RecordingStudio::Location::Location` children. Enable Location on `LocationSection`. Do not enable Location on `KitSection`. Do not copy `recording_studio_locations` into Press Kits.

This is not the kit-header place. PressKit still includes `Location.to`. `KitLocation` still finds the one optional Location child of the kit. A section place has a different parent.

The editor matches the other collection sections. Title and subtitle stay on the shared heading screen. Edit content is a `pk-editor` screen with + Location and the place list. New and edit use `recording_studio_location_search_fields`. Preview and the public page use `recording_studio_location_display`. Flatpack has no place-search or address card, so those stay Location's helpers. The display helper is a Card — fine in a section, too heavy for the hero byline (0.29.0). Section FAB, Orderable, and Trashable match the other sections.

```bash
bin/rails generate recording_studio_presskits:migrations
bin/rails db:migrate
```

Register `"RecordingStudioPresskits::LocationSection"`. Keep `"RecordingStudio::Location::Location"`. Keep Location at `~> 0.4` (dummy tag `v0.5.1`). Rebuild Tailwind. Pin Location Stimulus controllers if they are not already pinned.

When Recording Studio API is loaded, a kit section still returns `title`, `subtitle`, `content_type`, and `content_id`. `:locations` is declared on that output. The array is included only when the content type is `RecordingStudioPresskits::LocationSection`. Each entry is Location's `api_payload`. The Location section type returns `{ locations: ... }`. Do not register Location again from Press Kits.

## 0.32.0

A live kit can be downloaded as a zip of its public photos and a `kit.txt` of the public copy. PressKit opts into Downloadable (`source: :manifest`, action `:"presskits.kit_download"`, export scope `:public`). Presskits subscribes to Publishable's after-commit events: publish generates, unpublish invalidates immediately, a revision to a live kit rebuilds. Downloadable's debounce still covers ordinary content writes. The zip never includes drafts, unpublished revisions, trashed items, or private notes.

Default audience for `:"presskits.kit_download"` is public, with granted roles `download`, `edit`, and `admin` — not `view` alone. `allowed` includes registered custom audiences. Host and workspace constraints still apply; Accessible falls back to granted when public is not allowed. Hosts overwrite `RecordingStudioAccessible.configuration.action_audiences[:"presskits.kit_download"]`. `downloadable_available_for?` is true only while the kit is currently published. **Download kit** sits on the public page through Downloadable's button helper, including for logged-out visitors on a public kit. It stays off preview and the editor. Kit owners and editors change who may download from **Downloads** on the kit toolbar (`set_audience!`, `manage_role: :edit`). That screen uses a Flatpack RadioGroup `variant: :inline` with per-audience icons (`config.download_audience_icons` or i18n `recording_studio_presskits.downloads.audience_icons`).

Package show / create / status re-authorize on every request. Changing Anyone to Signed in immediately refuses an anonymous hit on the package path for a zip that is already built. A signed ActiveStorage blob URL already handed out stays valid until it expires — Downloadable uses `ActiveStorage.urls_expire_in` when positive, otherwise 5 minutes. Hosts that want a download-only grant declare `:download` in the root's `accessible_roles`; edit and admin grants already count. The public **Download kit** button follows the signed-in visitor, not a leftover `Current.actor`.

```bash
bin/rails generate recording_studio_downloadable:install
bin/rails generate recording_studio_downloadable:migrations
bin/rails generate recording_studio_accessible:migrations
bin/rails db:migrate
```

Bump Accessible to `~> 0.14` (dummy tag `v0.14.0`) and Publishable to `~> 0.7` (dummy tag `v0.7.0`). Pin Downloadable `~> 0.3` (dummy tag `v0.3.0`). Mount Downloadable, pin its Stimulus controllers, and rebuild Tailwind so the download button classes generate. Flatpack has no download-control component at this pin — do not invent one.

## 0.31.0

Images sections no longer attach files under the section. They hold Attachable `Placement` children that point at workspace library photos.

Rebuild seeds. A host that already attached files under an Images section should move those photos into the workspace library and place them.

Enable `include RecordingStudio::Capabilities::LibraryPlacement.to` and `Orderable.to(allows: ["RecordingStudioAttachable::Placement"])` on `RecordingStudioPresskits::Images`. Do not enable `Attachable.to` on that type. Quote still uses `Attachable.to` for one image.

**Add from library** and **Upload** live on the Images content screen in `pk-editor`. The picker is a pushed screen, not a nested modal. Upload writes the file into the library first (`upload_to_library_and_place`). `config.section_library_keys` can point a section type at a named library. Default is `:default`.

Public and preview resolve with `RecordingStudioPresskits::LibraryImages` (`Placements.resolve`). The kit cover uses the same helper. A trashed or missing photo is skipped. Dummy mounts the workspace library from Library → Images with `library_path_for`. Trash-in-use warnings and delete-removes-placements stay Attachable's job.

## 0.30.0

An optional cover image sits above the colour hero. Enable `include RecordingStudio::Capabilities::ImageLibrary.to` on the host root and `include RecordingStudio::Capabilities::LibraryPlacement.to` on PressKit. The first `place_library_image` result is the cover. Pick it with Attachable's placements screen and image picker. Do not add a second upload form or a cover-image model.

PressKit Orderable allows kit sections and `RecordingStudioAttachable::Placement` so resolve can see the photo. KitQuery and the Reorder screen still list only kit sections. Reordering sections keeps the placement on the kit.

The hero crops with `aspect-[1440/640]` and `object-cover`. Flatpack has no full-bleed crop image at this pin (`v0.1.224`). Colour-only grid cards stay 9/16. A kit with a photo shows the image and the title below it. The header-editor preview stays 9/16 and colour-only. The colour band title is `PageTitle` `size: :display`.

Dummy seeds Harbour Gallery on Spring launch from `db/seed_images/harbour-gallery.jpg`. Rebuild Tailwind so `aspect-[1440/640]` generates.

## 0.29.0

Company and Location sit on the kit hero. Company is a host opt-in on the root: `include RecordingStudio::Capabilities::Companies.to(allow: :one)`. One company per root. The hero calls `RecordingStudioCompany.company(root)` and paints `recording_studio_company_logo` plus the name. Skip the capability, or leave the place empty, and the row stays off.

Location is on the kit itself: PressKit includes `RecordingStudio::Capabilities::Location.to`. That is not a section and not a later Location section type. One optional child. `KitLocation` looks it up and writes it. The hero shows `resolved_icon` and `display_name`. The shared header screen in `pk-editor` edits it with `recording_studio_location_search_fields` (title, type, icon). Saving blank fields trashes the place. Saving the header without a `location` param leaves the place alone. Presskits enables Trashable on `RecordingStudio::Location::Location` so that clear works. Cover company lookup lives on `Cover::Company`. Header form parsing lives on `HeaderAttributes`.

Add the gems. Dummy pins Company `v0.3.0` and Location `v0.5.1`. Accessible moves to `~> 0.13` (`v0.13.0`), Attachable to `~> 0.13` (`v0.13.0`), Trashable to `~> 0.6` (`v0.6.0`). Flatpack is `>= 0.1.224` (dummy tag `v0.1.224`).

```bash
bin/rails generate recording_studio_company:install
bin/rails generate recording_studio_company:migrations
bin/rails generate recording_studio_location:install
bin/rails generate recording_studio_location:migrations
bin/rails db:migrate
```

Register `"RecordingStudioCompany::Company"` and `"RecordingStudio::Location::Location"`. Mount those engines. Pin Location's Stimulus controllers. Rebuild Tailwind so Location search-field classes generate. Flatpack `PageTitle` has no byline slot for a logo-plus-name row. Location's `recording_studio_location_display` is a Card — too heavy for the hero — so the hero uses Avatar + Icon + text.

## 0.28.0

The `:hero` cover is still a flush colour surface to the kit card's top and side edges. Height now comes from padding plus content: `p-12` on a phone, `md:p-24` (~96px) on a desktop. There is no 21/9 ratio and no `min-h-64`. Grid `:card` and the header-editor `:preview` stay 9/16.

A muted **Press kit** eyebrow sits above the title. The copy is `I18n.t("recording_studio_presskits.cover.eyebrow")` so a host can override it. Size is `text-3xl` / `md:text-4xl`. Colour is `color-mix(in oklab, <text colour> 70%, transparent)`. Flatpack `PageTitle` has no eyebrow or kicker slot, so the hero renders a semantic `<p>` with those tokens rather than a custom component.

The hero does not show the kit short description. Keep the field on the header screen, in the table, on the API payload, and on 9/16 cards. Title stays top-left and wraps as `FlatPack::PageTitle::Component` with `size: :display` in a `max-w-3xl` block. Display uses `--display-size` (`clamp` 48px to 88px), `--display-leading` `1.05`, `--display-tracking` `-0.03em`, and `--display-weight` `600`.

Bump Flatpack to `>= 0.1.224` (dummy tag `v0.1.224`) and rebuild Tailwind so `p-24`, `text-3xl`, `text-4xl`, and `text-8xl` generate. Reload Flatpack CSS for the 88px display clamp. Hosts that replaced `Cover::Component` should match this hero: no fixed ratio, eyebrow above `PageTitle` `size: :display`, no subtitle on the band.

## 0.26.0

The kit editor preview matches the public kit. In-flow **Edit heading**, **Edit content**, and the compact add-section dropdown are gone. On a pointer that can hover, hover or focus-within tints the region with `--surface-muted-background-color` and shows the FAB. Keyboard users get a `:focus-visible` outline and still see the FAB. On touch, the FAB is not always visible. A tap makes that section or the header the active region (tint and FAB). Tapping another region moves the active state. Tapping outside clears it.

Each section has `FlatPack::Fab::Component.new(contained: true, position: :top_right, backdrop: false, size: :sm, icon: :plus, offset: "1rem", label: "Section actions")` on a `position: relative` region so the FAB pins to that section. The region owns `p-8 md:p-10 lg:p-12` and `rounded-none` so the hover/active tint runs flush to the card sides. Phone padding stays `p-8`. Sections add `pr-20` so the heading clears the FAB. The kit card has no inner pad and no gap between sections — vertical section pad is the only space. The `:hero` cover is a flush colour surface (no nested Card) that runs to the kit card's top and side edges. The kit card uses `padding: :none`. The preview clips with `overflow-hidden` and `rounded-[var(--radius-lg)]` so the cover and the last section tint follow the card radius. Title and description sit at the top (`justify-start`) with `p-8 md:p-12` as the inset. Hero copy is `FlatPack::PageTitle::Component` with `size: :display` in a `max-w-2xl` block. The band stays 21/9 with `min-h-64`. `:card` and `:preview` are unchanged. Header hover and tap use an inset overlay instead of a surrounding muted tint. The header FAB sits inside the cover with `offset: "1rem"`. The public kit uses the same unpadded card, flush hero, and section-owned pad. Top corners open downward. Speed-dial actions:

- **Edit title** — shared heading screen in `pk-editor`
- **Edit content** — that section's content screen
- **Reorder** — existing Reorder modal, fragment focused on this section when the browser honors it
- **Trash** — `style: :danger`, `DELETE` through Trashable, with `data-turbo-confirm`
- **Add new section** — the section picker, with `after_recording_id` so the new block lands below this one

The kit header FAB uses the same chrome: **Edit heading** and **Cover colours**. Both open the shared header screen. Cover colours hashes to `#presskits-header-colours`. The toolbar **Section** button still adds at the end or into an empty kit.

Bump FlatPack to `>= 0.1.223` (dummy tag `v0.1.223`) and rebuild Tailwind so `text-6xl` / `text-7xl` generate. Reload Flatpack CSS for `--display-*` and `.fp-display`. Hosts that replaced those components should render the Flatpack FAB (`icon: :plus`, `offset: "1rem"`) on a `position: relative` region and drop the old ghost buttons, negative margins, and kit-level section pad or gap. Sections own `p-8 md:p-10 lg:p-12`, `pr-20`, and `rounded-none`. The header has no pad: the hero bleeds to the card and hover is an inset overlay. Hero copy sits at the top (`justify-start`) as `FlatPack::PageTitle::Component` with `size: :display` in a `max-w-2xl` block. Keep 21/9 with `min-h-64`. The kit card is `padding: :none`; the preview clips with `overflow-hidden`. The public kit uses the same unpadded card and section pad. FAB has no hover-only visibility or tap-to-activate API. Desktop uses group-hover / focus-within. Touch uses `recording-studio-presskits--editor-chrome` and `data-pk-edit-active`. The default cover palette swaps violet (`#7C3AED`) for sky (`#BFDBFE`) so the example kit can be a light cover with Auto dark text. Stored violet still renders. Add it back to `cover_colors` if you still want that swatch.

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
