# Dummy host

This Rails app exists to prove Recording Studio Press Kits in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus a seeded published press kit and an unpublished kit. No seeded fake sections
- Orderable, Trashable, Duplicatable, and Publishable install, migrations, and mounts
- Recording Studio Admin 2.0 mounted under an admin root, with Accessible grants for the seeded admin
- Authenticated `/` redirects to the press kit index on Recording Studio's default layout
- Cards and table views of kits. The heading is **My presskits**. **Presskit** with a Heroicons plus icon is first and left. Cards vs table is icon-only Flatpack ButtonGroup. Cards show a 16/9 cover, or the muted placeholder when `cover_image_url` is absent. Cards and the table open the two-column kit editor. That editor shows the kit name as the page heading. + Section is first, as a primary button, then the publish control, on a row above the two-column grid. Column one is one card. Header is the first row and opens the header screen. Update and Cancel sit above a two-column grid. Title and Short description are in column one. Column two previews them. That row has no drag handle and no remove. The header is the kit, so it cannot be removed or reordered. + Section stays the only primary button on the kit editor. When there are sections, they follow Header in that card as one FlatPack list. Each section is a list item. The link is the section type. The list is orderable and uses the divider. An arrows-up-down icon sits in the list icon slot. The drop is saved through Orderable. Remove is a trash icon and calls Trashable. An Images section stores a caption and many Attachable photos. Each photo's caption, credit, and alt text use Attachable's collection editor. The preview column is a card. There is no in-page Preview button. Publishable's menu still has View and Preview
- Logged-out public show of a live kit on the blank public layout (no page nav). A short description shows under the title when the kit has one
- Owner preview of a kit that is not live, on the default layout. **+ Access** is on the kit editor only
- + Section offers Text, Images, and Quotes, each with a Heroicon. The Text field is the FlatPack content editor and fills the section page. That editor hides the preview. The kit editor lists the section as Text inside a card, and the preview card renders the saved HTML. The public page renders it too. Dummy FakeBlock stays test-only and stays off the add dropdown
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

Authenticated screens keep `RecordingStudio::UsesDefaultLayout`. Dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps those screens (index, kit editor, section editor, owner preview, Admin). That is Flatpack's built-in rounded theme from `flat_pack/variables`. The override also links `flat_pack/application`, which paints primary and default buttons. The sign-in layout and the public blank layout link that sheet too. The same override passes Flatpack 0.1.133 `anchor_href` so the close X renders next to back. Devise sign-in keeps `layouts/application`, which already has the same html attribute. Default-layout chrome is back, close, and page actions. **+ Access** is in the slot on the kit editor only. The header screen leaves that slot empty. Sign out and Root Switchable stay out. The logged-out public kit uses `recording_studio_presskits/blank` (no page nav, no TopNav) and does not invent a Dummy host landing.

Dummy Tailwind must scan FlatPack components, Recording Studio's default layout, Admin, Publishable, Attachable, and this gem, or the host looks unstyled. `bin/rails tailwindcss:build` writes gem `@source` paths first. After changing views or gems, run that build (or `bin/dev`) so CSS is not an empty shell.
