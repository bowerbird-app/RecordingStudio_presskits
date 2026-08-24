# Project Guidelines

## Architecture

- This repository is Recording Studio Press Kits: a press kit is the container under a host root. Later addons supply the sections.
- Preserve engine namespace isolation under `RecordingStudioPresskits`.
- Treat `docs/gem_template/` as architectural reference material. The public README is the product. The dummy app is a host that proves the gem.
- Keep changes small and scoped. This slice has no editor, public page, publish, or API.

## UI Conventions

- FlatPack is the default UI system for later screens. This slice does not add product UI.
- The approved UI reference is the live FlatPack demo app at https://flatpack.bowerbird.io/ when you need to inspect current shared components and patterns.
- When editing ERB views, prefer `render FlatPack::...` components over custom HTML when an equivalent component exists.

## Testing

- The standard root validation command is `bundle exec rake test:all` from the repository root.
- If a change affects dummy app boot, assets, or migrations, also validate the dummy app setup the same way CI does.
- Cover Press kit declaration, root rejection, parent rejection, picker types, Accessible grants on the workspace root, Orderable reorder, Trashable trash/restore, and Duplicatable in-place copy in Minitest.

## Repo Conventions

- Writes go through `record`, `revise`, and `log_event!`. Reorder, trash, and duplicate go through the mixin APIs.
- Do not invent an ACL. Access uses `grant_access` / `authorized?` on recordings. Grants on the workspace root cover kits. Mixin writes authorize through Accessible.
- Later section addons opt in via `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Do not keep a list of block types in this gem.
- Orderable is on PressKit (the parent). Trashable is on PressKit and dummy FakeBlock. Duplicatable is on PressKit only.
- Enable those mixins with `include RecordingStudio::Capabilities::<Name>.to(...)` only. Do not use `.with`, a bare mixin include, or a second `enable_capability` path.
- Update docs when setup steps change. Keep the README as the product.
