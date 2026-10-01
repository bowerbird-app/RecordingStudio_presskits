# Dummy host

This Rails app exists to prove Recording Studio Press Kits in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus a seeded published press kit and an unpublished kit. No seeded fake sections
- Orderable, Trashable, Duplicatable, and Publishable install, migrations, and mounts
- Recording Studio Admin 2.0 mounted under an admin root, with Accessible grants for the seeded admin
- Authenticated `/` redirects to the press kit index on Recording Studio's default layout
- Cards and table views of kits. The heading is **My presskits**. **Presskit** with a Heroicons plus icon is first and left. Cards vs table is icon-only Flatpack ButtonGroup. Cards show a 16/9 cover, or the muted placeholder when `cover_image_url` is absent. Cards and the table open the two-column kit editor. That editor puts + Section first, as a primary button, then the publish control, on a row above the two-column grid. The title form is in column one, then one carded list per section. The link is the section type. The preview column is a card. There is no in-page Preview button. Publishable's menu still has View and Preview
- Logged-out public show of a live kit on the blank public layout (no page nav)
- Owner preview of a kit that is not live, on the default layout. **+ Access** is on the kit editor only
- + Section offers Text. The Text field is the FlatPack content editor and fills the section page. That editor hides the preview. The kit editor lists the section as Text inside a card, and the preview card renders the saved HTML. The public page renders it too. Dummy FakeBlock stays test-only and stays off the add dropdown
- Mounted `RecordingStudio::Engine` route behavior inside a host app

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - redirects to the press kit index
- `/recording_studio_presskits` - press kit index (cards or table)
- `/recording_studio_presskits/press_kits/:id` - redirects to the kit editor (edit access)
- `/recording_studio_presskits/press_kits/:id/edit` - kit editor
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

Authenticated screens keep `RecordingStudio::UsesDefaultLayout`. Dummy overrides `layouts/recording_studio/default_layout` so `<html data-theme="rounded">` wraps those screens (index, kit editor, section editor, owner preview, Admin). That is Flatpack's built-in rounded theme from `flat_pack/variables`. The same override passes Flatpack 0.1.133 `anchor_href` so the close X renders next to back. Devise sign-in keeps `layouts/application`, which already has the same html attribute. Default-layout chrome is back, close, and page actions. **+ Access** is in the slot on the kit editor only. Sign out and Root Switchable stay out. The logged-out public kit uses `recording_studio_presskits/blank` (no page nav, no TopNav) and does not invent a Dummy host landing.

Dummy Tailwind must scan FlatPack components, Recording Studio's default layout, Admin, Publishable, and this gem, or the host looks unstyled. `bin/rails tailwindcss:build` writes gem `@source` paths first. After changing views or gems, run that build (or `bin/dev`) so CSS is not an empty shell.
