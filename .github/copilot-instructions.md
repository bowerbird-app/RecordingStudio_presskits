# Project Guidelines

## Architecture

- This repository is Recording Studio Press Kits: a press kit is the container under a host root. Later addons supply the sections.
- Preserve engine namespace isolation under `RecordingStudioPresskits`.
- Treat `docs/gem_template/` as architectural reference material. The public README is the product. The dummy app is a host that proves the gem.
- Keep changes small and scoped. This slice ships the authenticated editor, a public page for a live kit, an owner preview, and Admin live vs not-live widgets. Do not enable Publishable on section children.

## UI Conventions

- FlatPack is the default UI system. Compose Card, Table, Grid, SegmentedButtons, EmptyState, Picker, PageTitle, PageNav, Button, and List. Cards vs table on the index is icon-only SegmentedButtons. Do not invent a custom view-mode widget.
- Every screen keeps `UsesDefaultLayout` — including logged-out public show — and puts Flatpack's built-in rounded theme on `<html data-theme="rounded">`. Dummy PageNav passes Flatpack 0.1.133 `anchor_href` so the close X renders. Do not invent a custom theme.
- Public live kits use `recording_studio/default_layout` via Publishable `.to` `public_layout`. Do not use Publishable's empty TopNav. Do not invent a press-kit public shell. Do not insert Sign in into that layout.
- The approved UI reference is the live FlatPack demo app at https://flatpack.bowerbird.io/ when you need to inspect current shared components and patterns.
- When editing ERB views, prefer `render FlatPack::...` components over custom HTML when an equivalent component exists.

## Testing

- The standard root validation command is `bundle exec rake test:all` from the repository root.
- If a change affects dummy app boot, assets, or migrations, also validate the dummy app setup the same way CI does.
- Cover Press kit declaration, mount, index cards and table, empty states, kit show with children, picker add, remove, reorder, publish/unpublish, indexable?, public read of a live kit, owner preview of a kit that is not live, Admin live vs not-live widgets, and Accessible 401/403 gates in Minitest.

## Repo Conventions

- Writes go through `record`, `revise`, and `log_event!`. Reorder, trash, and duplicate go through the mixin APIs. Publish through Publishable's services.
- Do not invent an ACL. Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits. Mixin writes authorize through Accessible.
- Later section addons opt in via `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Do not keep a list of block types in this gem. Picker uses declared parent types only.
- Orderable is on PressKit (the parent). Trashable is on PressKit and dummy FakeBlock. Duplicatable and Publishable are on PressKit only.
- Enable those mixins with `include RecordingStudio::Capabilities::<Name>.to(...)` only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path.
- Public lists use `PressKit.indexable`. Do not invent a second published query.
- Update docs when setup steps change. Keep the README as the product.
