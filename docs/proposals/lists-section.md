# Lists section

A press kit section for ordered labeled lines: a spec, an amenity, a short pair of words. The heading stays on the kit section. Each line is its own recording under a list section, so people can add, edit, reorder, and trash one line.

This is not Recording Studio Lists. That gem (`recording_studio_lists`) is a workspace collection: `RecordingStudio::Lists::List` and `RecordingStudio::Lists::ListItem`, tables `recording_studio_lists` and `recording_studio_list_items`, a pointer `item_recording_id`, and a `position` column. Press kits already depend on that gem for the add-to-list control on the kit index. A Lists section does not call it, store a recording id, or share those tables.

It is also thinner than Facts & Figures. A fact is a figure: label, value, unit, description, source, as-of date, and a display style. A list item is only an optional icon, a key, and a value.

Recording Studio is not in production. Ship the new types clean. No compatibility shim, no backfill, no reparent of old rows.

## What it holds

Same tree as quotes and facts:

```text
Press kit
└── Kit section          title, subtitle
    └── List section     orders its items, stores no heading
        ├── List item
        ├── List item
        └── List item
```

A kit can hold more than one list section. Each has its own heading. `create_section!` still takes an optional title. The add-section action uses the type label **List** when no title is passed, the same way Facts & Figures and Quotes get their labels.

| Place | Fields |
| --- | --- |
| `KitSection` | `title`, `subtitle`. Already there. The list section does not copy them. |
| `ListSection` | No columns. Same empty snapshot as `QuoteSection`. |
| `ListItem` | `icon` (optional), `key` (required), `value` (required). |

`key` is the short label. `value` is the string next to it. Both are plain text, stripped, and required. There is no rich text, no second detail line, and no URL.

`icon` stores an icon name from the set Flatpack already renders. The kit uses that set today: section menus, buttons, and list rows pass names such as `map-pin`, `photo`, and `list-bullet` as `icon:`, and the rendered control exposes `data-flat-pack--icon-name-value`. Blank becomes nil. A present name must be one of those names. An unknown name is invalid. The column does not store a file, a URL, or SVG markup.

These stay off the item:

- Unit, description, source, as-of date, and a display style. That is Facts & Figures.
- A rich-text body. That is Text. A text section can already contain a `<ul>`. A list section exists so each line is its own recording.
- A detail line and a link. The text of an item is the key and the value.
- An uploaded glyph. The icon is a name. A custom file is an open question below.
- A pointer at a workspace recording. That is a credit line, and it is also what Recording Studio Lists stores.

The public page shows the rows in saved order. The icon is the marker. There is no bullet or number setting.

## Data model and migration

Two recordables. Both are product-managed objects in the tree: people create them, revise them, and a kit duplicate should copy them. Do not store the lines as JSON on the section. Do not add a `position` column. Orderable already keeps order on the recording.

`RecordingStudioPresskits::ListSection`

- Table `recording_studio_list_sections`. This name does not collide with `recording_studio_lists`.
- `recording_studio_recordable label: "List", root: false, allowed_parent_types: ["RecordingStudioPresskits::KitSection"]`
- `Trashable.to`
- `Orderable.to(allows: ["RecordingStudioPresskits::ListItem"])`
- `section_menu_icon` returns `"list-bullet"`
- `active_items(recording)` returns `recording_studio_orderable_children` with trashed rows and non-items rejected, the same filter as `FactsSection.active_facts`

`RecordingStudioPresskits::ListItem`

- Table `recording_studio_kit_list_items`. Do not use `recording_studio_list_items`. That table belongs to Recording Studio Lists.
- `recording_studio_recordable label: "Item", root: false, allowed_parent_types: ["RecordingStudioPresskits::ListSection"]`
- `Trashable.to`
- No Orderable, Publishable, Duplicatable, Attachable, or Location. The press kit already duplicates with `exclude_children: []`, so a copied kit copies the list section and its items. Publishable stays on the kit. Attachable stays off because the icon is a name, not a file.

Snapshot tables follow quotes and facts: uuid primary key, `created_at` only, no `updated_at`.

```ruby
create_table :recording_studio_list_sections, id: :uuid do |t|
  t.datetime :created_at, null: false
end

create_table :recording_studio_kit_list_items, id: :uuid do |t|
  t.string :icon
  t.string :key, null: false, default: ""
  t.text :value, null: false, default: ""
  t.datetime :created_at, null: false
end
```

`key` is a string column. `value` is `text`, the same shape as `Fact#value`, so a longer line is not cut off. Both are plain strings in the product.

One migration in `db/migrate` and the same file under `test/dummy/db/migrate`, matching `20261008180000_create_recording_studio_facts.rb`. `down` can drop both tables. There is no data to preserve.

Writes go through the root. Create an item with `list_section_recording.record(ListItem, parent_recording: list_section_recording)`. Change one with `root.revise`. Trash with `recording_studio_trashable_trash!`. Do not insert `Recording` or `Event` rows.

Before validation, strip `key` and `value`, and store a blank `icon` as nil. `key` and `value` are required. `icon`, when present, is included in the Flatpack icon names the app already passes to `icon:`. Do not add a second icon catalog.

## How it plugs into the section framework

`Engine.register_builtin_sections` gains `register_list_section`, next to the other seven:

```ruby
RecordingStudioPresskits.register_section(
  "RecordingStudioPresskits::ListSection",
  component: "RecordingStudioPresskits::ListSection::Component",
  editor: "RecordingStudioPresskits::ListSection::EditComponent"
)
```

No `prepare` hook. A new list starts empty. Text is the section that seeds a body.

`register_section` is what puts **List** on the + Section menu. `section?` stays true only for `KitSection`. `picker_types` already keeps types whose declared parent is `KitSection` and that are listed in `section_types`. Registering the section is enough for the menu, as long as the host lists both classes in `recordable_types`.

`SectionComposer.create!` already records the kit section and the content type in one transaction. `SectionsController#create` already accepts any picker type, defaults the title from the type label, and positions the new kit section with `after_recording_id`. No new create path.

`KitQuery.section_content` returns the active child whose type is a registered section type. After registration, that child is the list section.

`SectionFrameComponent` already renders the component registered for the content type, and it already draws the kit-section title and subtitle. The list component does not draw that heading.

Files that name every section type today, and need the new one when this is built:

- `lib/recording_studio_presskits/engine.rb`
- `test/dummy/config/initializers/recording_studio.rb`
- `lib/generators/recording_studio_presskits/install/templates/INSTALL.md`
- `README.md` and `MIGRATION_NOTES.md`
- `app/components/recording_studio_presskits/press_kits/empty_section_placeholder_component.rb` (`PLACEHOLDER_KEYS`)
- `config/locales/recording_studio_presskits.en.yml` (placeholder and picker description)
- `lib/recording_studio_presskits/kit_download/text_file.rb`
- `lib/recording_studio_presskits/api.rb` and `SectionPayload`

Picker copy, looked up as `picker_descriptions.list_section` because the key is the demodulized class name:

- Menu label: List
- Icon: `list-bullet`
- Description: "Labeled lines, in the order you want."
- Empty kit card: "Add a line"

## Editing

A list line is written here. It is not picked from a workspace catalog, so a search column and a modal create do not fit. The section editor uses `FlatPack::CollectionEditor::Component`, the same component credits uses, with a row of Icon, Key, and Value instead of a drill-down list.

`ListSection::EditComponent` takes `recording:` and `update_path:`. Class methods:

- `param_key` → `:list_section`
- `permitted_attributes` → `[]`
- `below?` → `true`

`SectionEditorComponent` then renders `section_actions` and the editor outside the shared content form. Title, subtitle, and Update stay on `SectionHeadingEditorComponent`. The content screen has no display-style form, because the section stores none.

**Item** is the collection editor add button. It inserts a row. It does not record a blank item. Key and value are required, so **Save** rejects a row that is missing either one. Icon is a Flatpack select of outline names, with None for no icon.

The item screen is `ListItem::EditComponent` on `list_items/new` and `list_items/edit`, with the modal wrapper facts use when `presskits_editor_dialog?` is set. Fields, in order:

- **Icon.** Optional. A choice of Flatpack icon names, the same names buttons and section rows already use. Look up Flatpack before adding a control. Use an existing icon picker if one is there. If the only API today is the `icon:` argument, use a Flatpack select of those names. The stored value is the name, such as `star`. Empty means no icon. Do not offer a file field here.
- **Key.** Required. The short label.
- **Value.** Required. The string.

Save revises the item. A missing key, a missing value, or an unknown icon name re-renders the form.

The content tab is that collection editor. Headers are Icon, Key, and Value. The icon column is `7rem`. Key and Value take the remaining width. Dragging a saved row posts `moving_recording_id` and `target_position` to the item order route, which `QuoteOrder` already accepts. **Save** walks the rows: record a new line, `revise` a changed line, and `recording_studio_trashable_trash!` a removed line. The empty text is "No lines yet".

Routes, nested under `press_kits` / `sections` like facts:

```ruby
resources :list_items, only: %i[new create edit update destroy]
resource :list_item_order, only: :update, controller: "list_item_orders"
```

`ListItemsController` and `ListItemOrdersController` copy `FactsController` and `FactOrdersController`: load the kit, load the kit section, require the content recording to be a `ListSection`, authorize `:edit`. Create and update permit `:icon`, `:key`, `:value`.

Removing the section stays on `SectionsController#destroy`. That trashes the kit section. It does not delete rows. `KitQuery.sections_for` drops a trashed kit section, so the lines leave the public page with it. Restoring the kit section brings them back. Trashing one item leaves the section.

## Public rendering and preview

`ListSection::Component` takes `recording:`. `render?` is true only when `active_items` is non-empty. An empty list does not leave a blank card. An item with a blank key or value is not shown, the same way a quote with a blank body is skipped.

`SectionFrameComponent#content_visible?` uses that `render?`. Effects that already key off it:

- The kit editor shows `EmptySectionPlaceholderComponent` ("Add a line") until an item exists, then renders the list component.
- The public page (`PublicShowComponent`) skips the section.
- Preview uses the same frame, so an empty list stays out of the preview column.
- `KitDownload::TextFile` and `KitDownload::Manifest` skip the section. See below.

The public page and the kit preview render `FlatPack::List::Component` with one `FlatPack::List::Item` per line, in saved order. The icon uses the item's `icon:` argument, so the name becomes `data-flat-pack--icon-name-value`, and sits beside the key and the value the way a facts row pairs a label with its value. Six items or fewer stay one list, capped at `max-w-[65ch]`, the same measure as a text section. More than six split in saved order into two halves. Each half is its own list, placed in `FlatPack::Grid::Component` `cols: 2`, so a phone keeps one column and a wider window shows the halves side by side. That pair is capped at `max-w-[calc(130ch+1.5rem)]`. A blank icon leaves that slot empty and does not invent a default glyph. Key stays muted. Value stays medium. No link, no second paragraph, no numbers.

The component does not print the kit-section title or subtitle.

Saving an item from the kit editor uses `respond_with_preview_or_redirect`. A turbo request from the editor renders `editor/preview_section.turbo_stream.erb`, which replaces `presskits-section-{kit_section_id}`. That stream is shared. The list section does not add one.

## Ordering

Two levels, both already in the app.

**Sections.** The press kit's Orderable allows only `KitSection`. A list section is a kit section, so it shows up in `KitQuery.sections_for`, the Order modal (`SectionsOrderComponent`), and `OrdersController`. Drag posts `recording_id` plus `before_recording_id` or `after_recording_id` through `section_order_controller.js` to the kit order route. `SectionsController#create` still honors `after_recording_id` when the menu inserts a section under another one. Create, update, and destroy turbo streams already refresh `presskits-section-list`. Nothing new at this level.

**Items.** `ListSection` is Orderable for `ListItem` only. The collection editor's drag handle posts `moving_recording_id` and `target_position`. `ListItemOrdersController#update` calls `QuoteOrder` with `recordable_type: "RecordingStudioPresskits::ListItem"`. That class already accepts `ordered_recording_ids`, or a move via `recording_id` / `moving_recording_id` and `before_recording_id`, `after_recording_id`, or `target_position`. Facts and credit lines use it the same way. Do not add a second order class.

A JSON reorder returns `{ ok: true }`, which is what the collection editor drag expects. An HTML reorder redirects to the section edit with "Order saved." Saving the collection also writes the row order. There is no credits live-preview script.

Position lives on the item recordings. Reorder history is an event on the list section recording, written by Orderable.

## Download and manifest

`KitDownload::Manifest` stays cover images, Images-section photos, and `kit.txt`. A list item has no blob, so it adds no zip entry and no filename. The icon name is not a file.

`KitDownload::TextFile#content_handler_for` gains `ListSection => :list_lines`. `list_lines` walks `ListSection.active_items` and prints each item on one line:

```text
Capacity: 120 seats
```

That is `key`, then `: `, then `value`. Do not print the icon name. A press kit text file is the words. The icon is only on the page.

Skip an item whose key or value is blank. Skip trashed items by using `active_items`. The section block already starts with the kit-section heading and subtitle. A section whose component `render?` is false is omitted, so an empty list does not appear in `kit.txt`.

No new locale key is required. Facts prefix a line with `Fact:` and then the label. A list line should not add another prefix, because the heading above it is the list title.

Publish, unpublish, and revise already regenerate or invalidate the zip through `KitDownload.subscribe!`. A list edit that revises the kit's published tree follows that path. No new subscriber.

## API

Register both types from `Api.register_recordable_types`, the way facts are registered.

`ListItem`: operations `index`, `show`, `create`, `update`, `destroy`. Writable and output keys: `icon`, `key`, `value`. A blank icon serializes as nil. A withheld item serializes all three as nil.

`ListSection`: `index` and `show` with the empty serializer and empty `output_keys`, like `QuoteSection`. It has no attributes to update.

`SectionPayload#extras_for` adds the list section case. The kit section show payload gains `items`, an array of item payloads in order, from `active_items`. Withheld kit sections stay title, subtitle, content type, and content id all nil, and do not include items. `KitSection` `output_keys` gains `:items` next to `:facts`, `:videos`, and `:locations`.

No new capability action. Adding a section is still `create_section` with `content_type: "RecordingStudioPresskits::ListSection"`. Removing it is still `remove_section`. Reordering sections is still `reorder_sections`. Creating and updating a line is the `ListItem` recordable API. Facts and quotes also have no reorder capability action. Item reorder stays on the UI order route. See open questions.

## Tests

Behavior lands with tests in the same change. Mirror facts.

Gem suite:

- `test/recording_studio_declarations_test.rb`. Declare both types. Parent of `ListSection` is `KitSection`. Parent of `ListItem` is `ListSection`. Neither is a root. `ListSection` is not allowed under the press kit or the workspace. Orderable on `ListSection` allows only `ListItem`. Trashable on both. Publishable, Duplicatable, and Attachable off both. Menu icon `list-bullet`. Label "List".
- `test/list_item_payload_test.rb` (new), beside `test/fact_payload_test.rb`. Payload keys are `icon`, `key`, and `value`. A blank icon is nil. A withheld item is all nil. Kit section `items` stay in order. A trashed item is omitted. An empty section serializes `items: []`.
- `test/kit_download_test.rb` or the text-file coverage next to it. A list section contributes `Key: Value` lines to `kit.txt`, omits the icon name, and adds no zip file. A trashed item and an empty list stay out.
- `test/recording_studio_presskits_test.rb`. Engine source includes `register_list_section`. README and the install guide mention `ListSection` once those docs are updated.

Dummy suite:

- `test/dummy/test/integration/list_section_test.rb`. `create_section!` writes the kit section and an empty list section in one transaction and does not write an item. Two list sections on one kit keep their own items. The editor adds, edits, reorders, and trashes an item. A blank key or value re-renders. An unknown icon name re-renders. A blank icon saves as nil. Trashing the section removes it from `KitQuery.sections_for` and leaves the rows. Public and preview HTML show the heading, the icon name on `data-flat-pack--icon-name-value`, the key, and the value. A section with no items is hidden. A row with no icon has no icon name.
- `test/dummy/test/integration/press_kit_ui_test.rb`. The picker row is List, the description is the new sentence, the icon is `list-bullet`.
- `test/dummy/test/integration/press_kit_download_test.rb`. Extend the manifest example with one list so `kit.txt` includes `Key: Value`, excludes the icon name, and excludes a trashed line.
- `test/dummy/config/initializers/recording_studio.rb` lists both types. `RecordingStudio.validate_recordable_declarations!` keeps passing.

Model assertions, in the integration test or a small gem test: `key` and `value` presence, blank icon stored as nil, a known name such as `star` accepted, an unknown name rejected.

No test should require `RecordingStudio::Lists::List` or `recording_studio_list_items`.

## Docs to update with the implementation

`README.md` gets a Lists paragraph next to Facts, in the same shape: two recordings, fields, icon name, editor, public page, order, trash. The picker sentence that lists type names and icons gains List / `list-bullet`. The install step that registers recordable types gains both class names.

`MIGRATION_NOTES.md` tells hosts to run the new migration and add the two types. There is no data move.

`CHANGELOG.md` and the gem version bump belong to the implementation branch, not to this proposal.

## Open questions

1. **Custom icon uploads.** This proposal stores a Flatpack icon name and does not attach a file. A host that needs a drawn mark would put Attachable on `ListItem` (one image, the way a quote has one image), render that file on the public row, and add the blob to the kit zip. That is a different column, a different editor control, and a manifest change. Leave it out until someone asks. Do not store both a name and a file on the first version.

2. **API reorder.** The UI can reorder items. Facts and quotes do not expose a reorder capability action, so this proposal does not either. An agent that can add items still cannot reorder them except by whatever Orderable already exposes on its own. Add `reorder_items` on `ListSection`, implemented with `QuoteOrder`, if agents need the same action as the editor.
