---
name: recording-studio-presskit-editor
description: Rebuild the press kit editor in recording_studio_presskits into one kit screen and one section screen. Use when you replace the kit show and kit edit pair, add the two-column kit preview, or add a section edit page.
---

# Build the press kit editor

Give the person editing a kit one screen, and give each section its own screen. This gem stays the container. Later addons supply section fields.

Follow `recording-studio-ui`, `recording-studio-flatpack`, and `recording-studio-text`. Do not restate them.

## Remove the show and edit pair

`PressKits::ShowComponent` branches on `editing?`. Delete that branch before you add the columns.

Build `PressKits::KitEditorComponent` for the kit screen. Build `PressKits::SectionEditorComponent` for one section. Delete `ShowComponent` in the same change, including `editing?`.

Redirect `PressKitsController#show` to `edit_press_kit_path`. Keep `authorize_recording!` with `role: :edit` on `edit`. People who can only view a kit use the owner preview and the public page.

Point the index `show_path` in `press_kits/index.html.erb` at `edit_press_kit_path`. Cards and the table open the kit editor.

Remove the Edit button and the in-page Preview button from the kit screen.

Keep `PressKitsController#preview`. That action is the owner preview. Keep the publish menu View and Preview items. Those open the public URL. Keep `public_layout` as `recording_studio_presskits/blank`.

## Build the kit editor

Keep the route `GET /recording_studio_presskits/press_kits/:id/edit`.

Render `FlatPack::Grid::Component` with `cols: 2`, `gap: :lg`, and `align: :start`. `cols: 2` is one column below the `md` breakpoint and two columns from `md` up. Put the form in the first child. Put the preview in the second child. On a narrow screen the form sits above the preview.

Put these in column 1, in this order:

1. `render_publishable_quick_actions` for the kit recording.
2. `SectionDropdownComponent`, labeled Add a section.
3. The title field and Save. Post Save to `press_kit_path` with `press_kit[title]`, the same write `PressKitsController#update` already uses.
4. One row per section already on the kit.

Column 2 renders every section through `RecordingStudioPresskits.section_component_for`. Omit a page title in that column. Leave the owner-preview alert on `PublicShowComponent`. Show that alert only when `preview` is true and the kit is not live.

A row shows the type label and the title, and links to that section's edit page. Keep Move up, Move down, and Remove on the row. Those controls already live on `PressKits::ChildComponent`. Render the public section component in column 2 only.

Leave Add a section disabled when `RecordingStudioPresskits.picker_types` is empty. The dummy app excludes FakeBlock, so the control stays disabled until an addon declares `allowed_parent_types: ["RecordingStudioPresskits::PressKit"]`. Do not hardcode section types in this gem.

Keep Access in the page-nav right slot. `presskits_page_nav` already fills that slot.

## Build the section editor

Add `edit` and `update` to the nested `sections` resource in `config/routes.rb`. The page is `GET /recording_studio_presskits/press_kits/:press_kit_id/sections/:id/edit`.

Use the same grid.

Column 1 renders only the registered editor for that section. Column 2 renders only that section, through `section_component_for`.

On a successful `SectionsController#create`, redirect to the new section's edit page. Replace the notice `Section added. Drag to change the order.` with a short notice that the section was added. Follow `recording-studio-text`. Failure redirects stay on the kit editor.

Back and close return to the kit editor. Keep Access in the page-nav right slot.

`SectionsController#update` calls `revise` on that section recording. Permit only the attributes the registered editor declares. See the registry below.

Remove on the section page returns to the kit editor. `SectionsController#destroy` already redirects there.

## Register a section editor

Store editors on `RecordingStudioPresskits::Configuration` next to `section_components`. Add `section_editors` to `to_h`.

```ruby
RecordingStudioPresskits.register_section_editor("Bio", "Bio::EditComponent")
```

`section_editor_for` resolves a class the same way `section_component_for` does. A registered class renders as-is. A string is constantized.

An editor class declares its write boundary:

```ruby
def self.param_key
  :bio
end

def self.permitted_attributes
  [:headline]
end
```

`SectionsController#update` permits `editor.param_key` with `editor.permitted_attributes` and no other keys.

When no editor is registered, the section page shows the recordable type label and Remove. Do not add Bio, download, or logo fields in this gem.

Publish stays on `PressKit` only. Do not enable Publishable on section children.

## Prove the screens

From the repository root, run `bundle exec rake test:all`.

Extend `test/dummy/test/integration/press_kit_ui_test.rb`. Sign in and assert the page:

- The kit edit page shows the publish control, Add a section, the title field, each section row, and the kit preview.
- The kit edit page has no Edit button and no in-page Preview button.
- A section row links to that section's edit page.
- The section edit page shows that section in the preview and does not show the other sections there.
- `GET` the kit show path and follow the redirect to the kit edit page.
- Index cards and the table link to the kit edit page.
- Add a section stays disabled when `picker_types` is empty.
