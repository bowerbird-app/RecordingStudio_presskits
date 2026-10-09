# Dummy host

This Rails app exists to prove Recording Studio Press Kits in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus a seeded published press kit and an unpublished kit. No seeded fake sections
- Orderable, Trashable, Duplicatable, and Publishable install, migrations, and mounts
- Recording Studio Admin 2.0 mounted under an admin root, with Accessible grants for the seeded admin
- Authenticated `/` redirects to the press kit index on Recording Studio's default layout
- Cards and table views of kits, inside a sidebar. The heading is **My presskits**. **Presskit** with a Heroicons plus icon is first and left. Cards vs table is icon-only Flatpack ButtonGroup. Library is a collapsible group in the sidebar, and Credits is the link under it. Cards show a 16/9 cover, or the muted placeholder when `cover_image_url` is absent. Cards and the table open the kit editor. That page is the live kit, full width, inside a card. A slim toolbar holds Section, Order, and the publish control. Each section, including the kit title, has Edit heading on hover. Sections also have Edit content. Those open one navigable Flatpack modal (`pk-editor`). Child items such as facts and quotes push further screens in that modal. Section opens a list of types and creates the chosen block at once. Empty sections show an Add placeholder. Order opens Reorder, which drags through Orderable. There is no in-page View or Preview button. Publishable's menu still has View and Preview
- Logged-out public show of a live kit on the blank public layout (no page nav). A short description shows under the title when the kit has one
- Owner preview of a kit that is not live, on the default layout. **+ Access** is on the kit editor only
- Section offers Text, Images, Quotes, Credits, and Video, each with a Heroicon and a short line on why that block helps a press kit. Heading editing is one shared screen titled Section heading: Title, Subtitle, and Update. A new section starts with that type's label as the title. Content editors only edit their own data. Body has its own Update. A Credits section uses a collection editor to search for a credit or create one, and to set that credit's role on the kit. Video opens a screen for one video link. YouTube ships with External Embed. Press Kits does not register Vimeo. The Text field is the FlatPack content editor. Dummy FakeBlock is a registered section that stays off the add list
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
- `/recording_studio_presskits/press_kits/:id/header/edit` - header title and short description
- `/published/:uuid/:slug` - public show of a live kit
- `/recording_studio_presskits/press_kits/:id/preview` - owner preview
- `/admin` - Admin live vs not-live kits
- `/recording_studio` - redirects to the press kit index while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/recording_studio_orderable` - Orderable engine mount from its install generator
- `/recording_studio_trashable` - Trashable engine mount from its install generator
- `/recording_studio_duplicatable` - Duplicatable engine mount from its install generator
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify press kits boot in a host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem likely needs adjustment before reuse.

Authenticated screens keep `RecordingStudio::UsesDefaultLayout`. Dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps those screens (index, kit editor, section editor, owner preview, Admin). That is Flatpack's built-in rounded theme from `flat_pack/variables`. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack `anchor_href` for the close X. The layout draws one back control: the screen's back URL when it sets one, and PageNav's history button when it does not. Devise sign-in keeps `layouts/application`, which already has the same html attribute. Default-layout chrome is back, close, and page actions. **+ Access** is in the slot on the kit editor only. The header screen leaves that slot empty. Sign out and Root Switchable stay out. The logged-out public kit uses `recording_studio_presskits/blank` (no page nav, no TopNav) and does not invent a Dummy host landing.

Dummy Tailwind must scan FlatPack components, Recording Studio's default layout, Admin, Publishable, Attachable, and this gem, or the host looks unstyled. `bin/rails tailwindcss:build` writes gem `@source` paths first. After changing views or gems, run that build (or `bin/dev`) so CSS is not an empty shell.
