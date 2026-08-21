# Project Guidelines

## Architecture

- This repository is Recording Studio Press Kits: a press kit is the container under a host root. Later addons supply the sections.
- Preserve engine namespace isolation under `RecordingStudioPresskits`.
- Treat `docs/gem_template/` as architectural reference material. The public README is the product. The dummy app is a host that proves the gem.
- Keep changes small and scoped. This slice ships the authenticated editor and one Admin list. It has no public page, publish, or API.

## UI Conventions

- FlatPack is the default UI system. Compose Card, Table, Grid, SegmentedButtons, EmptyState, Picker, PageTitle, PageNav, Button, and List. Do not invent a custom view-mode widget.
- Dummy authenticated screens keep `UsesDefaultLayout` and put Flatpack's built-in rounded theme on `<html data-theme="rounded">`. Do not invent a custom theme.
- The approved UI reference is the live FlatPack demo app at https://flatpack.bowerbird.io/ when you need to inspect current shared components and patterns.
- When editing ERB views, prefer `render FlatPack::...` components over custom HTML when an equivalent component exists.

## Testing

- The standard root validation command is `bundle exec rake test:all` from the repository root.
- If a change affects dummy app boot, assets, or migrations, also validate the dummy app setup the same way CI does.
- Cover Press kit declaration, mount, index cards and table, empty states, kit show with children, picker add, remove, reorder, Admin list widget, and Accessible 401/403 gates in Minitest.

## Repo Conventions

- Writes go through `record`, `revise`, and `log_event!`. Reorder, trash, and duplicate go through the mixin APIs.
- Do not invent an ACL. Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits. Mixin writes authorize through Accessible.
- Later section addons opt in via `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Do not keep a list of block types in this gem.
- Orderable is on PressKit (the parent). Trashable is on PressKit and dummy FakeBlock. Duplicatable is on PressKit only.
- Enable those mixins with `include RecordingStudio::Capabilities::<Name>.to(...)` only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path.
- Update docs when setup steps change. Keep the README as the product.
