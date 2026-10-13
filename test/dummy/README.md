# Dummy host

This Rails app exists to prove Recording Studio Press Kits in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus a seeded published press kit (**Spring launch**, Harbour Gallery cover photo attached on the kit, **Press photos** Images section with its own copy of that photo, **Harbour Studio** company, **Harbour Gallery** kit location, **Where to find us** Location section with The Pavilion in Melbourne), an unpublished kit, and three visibility kits: **Members only launch** (signed in, preview), **Invite only launch** (granted, preview), and **Quiet launch** (granted, hidden). Short descriptions on those kits stay kit copy, not the access message. No seeded fake sections. A development stand-in in `stand_in/acme_desk_branding.rb` paints **ACME desk** as `#0F766E` serif so **Spring film** can inherit and **House style** can override with `#DB2777` mono. The initializer loads it only in development, outside the autoload path. That stand-in is not the press centers gem.
- Dummy `Showcase` includes `RecordingStudio::Capabilities::PressKits.to` so a kit can sit under a showcase. It is a test recordable, not a screen. Workspace stays the only parent named on PressKit
- Orderable, Trashable, Duplicatable, Publishable, Downloadable, Company, Location, and Attachable install, migrations, and mounts. Dummy Workspace enables `Companies.to(allow: :one)` and Accessible `:action_audiences` so kit visibility can be limited and a live kit can be downloaded as a zip of its public photos and `kit.txt`. Accessible is `v0.15.0`. Publishable is `v0.8.0`. **Download kit** sits on the public page for someone who may take `:"presskits.kit_download"` (default: public, so logged-out visitors can take a live kit). Granted roles stay download / edit / admin — not view alone. It stays off preview. **Downloads** on the kit editor toolbar is who may take the zip. The package path re-checks that setting on every request; a signed blob URL already issued remains a bearer link until it expires (default 5 minutes).
- Recording Studio Admin 2.0 mounted under an admin root, with Accessible grants for the seeded admin
- Authenticated `/` redirects to the press kit index on Recording Studio's default layout
- Cards and table views of kits, inside a sidebar. The heading is **My presskits**. **Presskit** with a Heroicons plus icon is first and left. Cards vs table is icon-only Flatpack ButtonGroup. Library is a collapsible group in the sidebar. Credits is the credit list. Images are attached on the kit, not opened from the sidebar. Cards are `Cover::Component` at `:card`: a white rounded card. The top is the cover photo, or a muted frame when there is no photo, with Flatpack's default Press kit badge (muted surface `#e5e5e5`, text `#333` on the rounded theme). Below that the company name sits just above the title, with a heart for Lists on that row when someone is signed in, then an optional subtitle, a short description clamped to three lines, and a View button pinned to the bottom of the card in the brand colour. When that card's container is at least 640px wide, the cover moves to the left half at full height and the body stays on the right. The company name, title, subtitle, heart, and description then sit lower: the copy adds `pt-16` on top of the body's `pt-7`. **View** stays pinned to the bottom, and **Edit** stays at the body's top-right inset. Narrower cards stay stacked and keep only the body's `pt-7`. The index does not add a second full-width copy of a kit. Cards and the table open the kit editor. That page is the live kit, full width. The kit header is the same `:card` at the full width of the preview, so the cover sits on the left and the body on the right. A slim toolbar holds Section, Order, Visibility (eye icon, opens pk-editor), Downloads (Heroicons `arrow-down-tray`, opens who can take the zip in the same `pk-editor` modal), and the publish control. **Visibility** and **Downloads** sit side by side on that row. The header card and each section are separate rounded white cards with the same soft shadow. `gap-6` sits between them. The short description shows in the card body. Kit location sits under the short description on the card. A blank short description puts it under the title and subtitle. Each section owns `p-8 md:p-10 lg:p-12` inside its card; the hover tint follows the card's rounded corners. Phone padding stays `p-8`. Header hover is an overlay on the cover, not a surrounding tint. Hover shows **Edit** at the top right of the card body. It opens location and brand. **Edit image** sits on the cover, opposite the Press kit badge, and opens the cover photo. Below 640px, and on touch, both stay visible and show only their icons. There is no plus FAB on the header. On the kit editor the title, subtitle, and short description edit in place on the card. An empty short description says Add a short description. Title is required. An empty title is blocked in place. A section has no FAB and no add of its own. Hover shows Order, Edit, and an icon-only trash button. Edit opens the content screen. Text sections hide Edit and edit the body in place. Below 640px, and on touch, the section row stays visible. Title and subtitle edit in place. An empty subtitle says Add a subtitle. Those editors open one navigable Flatpack modal (`pk-editor`). The header modal has a Location search (title, type, icon), Cover image (Upload or Change, and Remove), and Brand. When press centers is loaded, Brand is tabs: Press center and Custom. Without it, the font and colour swatches show on their own. The header form does not preview the card. The editor card shows the workspace company name when Companies are enabled, then the kit location. Child items such as facts and quotes push further screens in that modal. Section opens a list of types and creates the chosen block at once. Empty sections show an Add placeholder. Order opens Reorder, which drags through Orderable. There is no in-page View or Preview button. Publishable's menu still has View and Preview
- Logged-out public show of a live kit on the blank public layout (no page nav). The kit opens as the same stack of cards as the editor: the wide brand card, then one card per section with a gap between them. A limited preview puts the explanation in that section card under the header card. `Cover::Component` at `:card` is the header. The short description is on that card. When the visitor may download the kit, **Download kit** sits under the card (Downloadable's button helper). Signed-out visitors see it on a live public kit. Signed in hides the button until they sign in. People with access hides it from visitors without a download / edit / admin grant. A limited preview keeps the card, then a **See full press kit** heading and an access message. Signed-in kits offer Sign in and Create account (`/users/sign_in`, `/users/sign_up`). Dummy sets `config.site_name` to Harbour Studio so that copy names the site. Hidden kits 404 without kit HTML. An anonymous visit after an editor request in the same process still sees preview or hidden, not the full kit.
- Owner preview of a kit that is not live, on the default layout. **+ Access** is on the kit editor only
- Section offers Text, Images, Quotes, Credits, Video, and Location, each with a Heroicon and a short line on why that block helps a press kit. On the kit editor, the section title and subtitle edit in place. A direct visit can still open the shared heading screen: Title, Subtitle, and Update. A new section starts with that type's label as the title. Content editors only edit their own data. On the kit, a text body edits in place with the bubble toolbar. On the public kit the same copy uses the theme's muted text, about 65 characters wide. Long copy collapses to eight lines with a Show more button. A direct visit still shows Body and Update. An Images section uses Attachable's file button to add a photo, then Attachable's collection editor for caption, credit, alt, reorder, and Trash. A Credits section uses a collection editor to search for a credit or create one, and to set that credit's role on the kit. Video opens a screen for one video link. YouTube ships with External Embed. Press Kits does not register Vimeo. Location opens Location's search fields for one or more places. That is not the kit-header place. The Text field is the FlatPack content editor. Dummy FakeBlock is a registered section that stays off the add list
- Mounted `RecordingStudio::Engine` route behavior inside a host app

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Dummy credentials are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or write that key to `config/master.key` (gitignored). Do not mint a per-repo dummy key.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - redirects to the press kit index
- `/recording_studio_presskits` - press kit index (cards or table)
- `/recording_studio_presskits/press_kits/:id` - redirects to the kit editor (edit access)
- `/recording_studio_presskits/press_kits/:id/edit` - kit editor
- `/recording_studio_presskits/press_kits/:id/header/edit` - kit location, cover image, and brand
- `/recording_studio_presskits/press_kits/:id/visibility/edit` - Visibility: who can view the full kit, and what other visitors see
- `/recording_studio_presskits/press_kits/:id/downloads/edit` - who can download the kit zip
- `/published/:uuid/:slug` - public show of a live kit (full, limited preview, or 404 when hidden)
- `/recording_studio_downloadable` - Downloadable engine mount for kit zip builds and fetches
- `/recording_studio_presskits/press_kits/:id/preview` - owner preview
- `/admin` - Admin live vs not-live kits
- `/recording_studio` - redirects to the press kit index while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/recording_studio_orderable` - Orderable engine mount from its install generator
- `/recording_studio_trashable` - Trashable engine mount from its install generator
- `/recording_studio_duplicatable` - Duplicatable engine mount from its install generator
- `/users/sign_in` - Devise sign-in page
- `/users/sign_up` - Devise registration page (preview Create account)
- `/up` - Rails health check

## Why This App Exists

Use this app to verify press kits boot in a host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem likely needs adjustment before reuse.

Authenticated screens keep `RecordingStudio::UsesDefaultLayout`. Dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps those screens (index, kit editor, section editor, owner preview, Admin). That is Flatpack's built-in rounded theme from `flat_pack/variables`. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack `anchor_href` for the close X. The layout draws one back control: the screen's back URL when it sets one, and PageNav's history button when it does not. Devise sign-in keeps `layouts/application`, which already has the same html attribute. Default-layout chrome is back, close, and page actions. **+ Access** is in the slot on the kit editor only. The header screen leaves that slot empty. Sign out and Root Switchable stay out. The logged-out public kit uses `recording_studio_presskits/blank` (no page nav, no TopNav) and does not invent a Dummy host landing.

Dummy Tailwind must scan FlatPack components, Recording Studio's default layout, Admin, Publishable, Downloadable, Attachable, Company, Location, and this gem, or the host looks unstyled. `bin/rails tailwindcss:build` writes gem `@source` paths first. After changing views or gems, run that build (or `bin/dev`) so CSS is not an empty shell.
