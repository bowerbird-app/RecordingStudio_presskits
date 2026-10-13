# Lists section

A press kit section for an ordered set of lines: awards, stops, key points, a filmography. The heading stays on the kit section. Each line is its own recording under a list section, so people can add, edit, reorder, and trash one line.

This is not Recording Studio Lists. That gem (`recording_studio_lists`) is a workspace collection: `RecordingStudio::Lists::List` and `RecordingStudio::Lists::ListItem`, tables `recording_studio_lists` and `recording_studio_list_items`, a pointer `item_recording_id`, and a `position` column. Press kits already depend on that gem for the add-to-list control on the kit index. A Lists section does not call it, store a recording id, or share those tables.

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
| `ListItem` | `text` (required), `detail` (optional), `url` (optional). |

`text` is the line. `detail` is one optional second line (a year, a role, a short note). `url`, when present, is an HTTP or HTTPS link, validated the same way as `Fact#source_url` (`HTTP_URL`, blank allowed). Blank `detail` and `url` become nil on validation. `text` is stripped and required.

These fields stay off the item:

- A label/value pair. That is Facts & Figures.
- A rich-text body. That is Text. A text section can already contain a `<ul>`. A list section exists so each line is its own recording.
- A photo. Quotes have one image. A list line does not, so the kit zip does not grow a new file kind.
- A pointer at a workspace recording. That is a credit line, and it is also what Recording Studio Lists stores.

The public page shows a bulleted list in saved order. Numbers are not a display setting in this proposal. See open questions.

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
- No Orderable, Publishable, Duplicatable, Attachable, or Location. The press kit already duplicates with `exclude_children: []`, so a copied kit copies the list section and its items. Publishable stays on the kit.

Snapshot tables follow quotes and facts: uuid primary key, `created_at` only, no `updated_at`.

```ruby
create_table :recording_studio_list_sections, id: :uuid do |t|
  t.datetime :created_at, null: false
end

create_table :recording_studio_kit_list_items, id: :uuid do |t|
  t.string :text, null: false, default: ""
  t.text :detail
  t.string :url
  t.datetime :created_at, null: false
end
```

One migration in `db/migrate` and the same file under `test/dummy/db/migrate`, matching `20261008180000_create_recording_studio_facts.rb`. `down` can drop both tables. There is no data to preserve.

Writes go through the root. Create an item with `list_section_recording.record(ListItem, parent_recording: list_section_recording)`. Change one with `root.revise`. Trash with `recording_studio_trashable_trash!`. Do not insert `Recording` or `Event` rows.

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
- Description: "A few lines, in the order you want."
- Empty kit card: "Add a line"

## Editing

Follow facts and quotes, not the credits collection editor. A list line is written here. It is not picked from a workspace catalog, so a search column and a modal create do not fit.

`ListSection::EditComponent` takes `recording:` and `update_path:`. Class methods:

- `param_key` → `:list_section`
- `permitted_attributes` → `[]`
- `below?` → `true`

`SectionEditorComponent` then renders `section_actions` and the editor outside the shared content form. Title, subtitle, and Update stay on `SectionHeadingEditorComponent`. The content screen has no display-style form, because the section stores none.

**+ Item** is a primary button with a Heroicons plus icon and the label Item. It links to `new_press_kit_section_list_item_path`. That matches + Fact. Quotes can create a blank row because body and name default to `""`. Item text is required, so the new screen collects it before `record`, the same as facts.

The item screen is `ListItem::EditComponent` on `list_items/new` and `list_items/edit`, with the modal wrapper facts use when `presskits_editor_dialog?` is set. Fields: Text, Detail, Link. Detail and Link can be blank. Save revises the item. A validation error re-renders the form.

The content tab lists active items in order inside `FlatPack::List` (`orderable: true`, `divider: true`) and `FlatPack::Card`, with `recording-studio-presskits--section-order` pointed at the item order path. Each row links to the item editor and shows `text`, with `detail` as the muted second line when present. Trash posts delete and calls `recording_studio_trashable_trash!` on that item only. The empty state is `FlatPack::EmptyState` with title "No lines yet" and description "Add a point, an award, or a stop."

Routes, nested under `press_kits` / `sections` like facts:

```ruby
resources :list_items, only: %i[new create edit update destroy]
resource :list_item_order, only: :update, controller: "list_item_orders"
```

`ListItemsController` and `ListItemOrdersController` copy `FactsController` and `FactOrdersController`: load the kit, load the kit section, require the content recording to be a `ListSection`, authorize `:edit`. Create and update permit `:text`, `:detail`, `:url`.

Removing the section stays on `SectionsController#destroy`. That trashes the kit section. It does not delete rows. `KitQuery.sections_for` drops a trashed kit section, so the lines leave the public page with it. Restoring the kit section brings them back. Trashing one item leaves the section.

## Public rendering and preview

`ListSection::Component` takes `recording:`. `render?` is true only when `active_items` is non-empty. An empty list does not leave a blank card.

`SectionFrameComponent#content_visible?` uses that `render?`. Effects that already key off it:

- The kit editor shows `EmptySectionPlaceholderComponent` ("Add a line") until an item exists, then renders the list component.
- The public page (`PublicShowComponent`) skips the section.
- Preview uses the same frame, so an empty list stays out of the preview column.
- `KitDownload::TextFile` and `KitDownload::Manifest` skip the section. See below.

The public list is a stack of lines in order, in the same type sizes as the facts list: `text` at `text-base font-medium`, `detail` at `text-sm` muted. A present `url` is rendered only after `FlatPack::AttributeSanitizer.sanitize_url`, and the line links to it. A rejected URL is not shown as a link. Bullets, not numbers.

The component does not print the kit-section title or subtitle.

Saving an item from the kit editor uses `respond_with_preview_or_redirect`. A turbo request from the editor renders `editor/preview_section.turbo_stream.erb`, which replaces `presskits-section-{kit_section_id}`. That stream is shared. The list section does not add one.

## Ordering

Two levels, both already in the app.

**Sections.** The press kit's Orderable allows only `KitSection`. A list section is a kit section, so it shows up in `KitQuery.sections_for`, the Order modal (`SectionsOrderComponent`), and `OrdersController`. Drag posts `recording_id` plus `before_recording_id` or `after_recording_id` through `section_order_controller.js` to the kit order route. `SectionsController#create` still honors `after_recording_id` when the menu inserts a section under another one. Create, update, and destroy turbo streams already refresh `presskits-section-list`. Nothing new at this level.

**Items.** `ListSection` is Orderable for `ListItem` only. The editor list uses the same Stimulus controller. `ListItemOrdersController#update` calls `QuoteOrder` with `recordable_type: "RecordingStudioPresskits::ListItem"`. That class already accepts `ordered_recording_ids`, or a move via `recording_id` / `moving_recording_id` and `before_recording_id`, `after_recording_id`, or `target_position`. Facts and credit lines use it the same way. Do not add a second order class.

A saved item reorder redirects to the section edit with "Order saved.", matching facts. It does not get the credits live-preview script. Credits need that script because their rows are an unsaved collection form. List rows are already saved recordings.

Position lives on the item recordings. Reorder history is an event on the list section recording, written by Orderable.

## Download and manifest

`KitDownload::Manifest` stays cover images, Images-section photos, and `kit.txt`. A list item has no blob, so it adds no zip entry and no filename.

`KitDownload::TextFile#content_handler_for` gains `ListSection => :list_lines`. `list_lines` walks `ListSection.active_items` and prints each item as:

```text
Line text
Optional detail
https://example.com/optional
```

Skip an item whose `text` is blank. Skip trashed items by using `active_items`. The section block already starts with the kit-section heading and subtitle. A section whose component `render?` is false is omitted, so an empty list does not appear in `kit.txt`.

No new locale key is required if the lines are plain. Facts prefix a line with `Fact:`. A list line should not, because the heading above it is the list title.

Publish, unpublish, and revise already regenerate or invalidate the zip through `KitDownload.subscribe!`. A list edit that revises the kit's published tree follows that path. No new subscriber.

## API

Register both types from `Api.register_recordable_types`, the way facts are registered.

`ListItem`: operations `index`, `show`, `create`, `update`, `destroy`. Writable and output keys: `text`, `detail`, `url`. Blank optional fields serialize as nil. A withheld item serializes all three as nil.

`ListSection`: `index` and `show` with the empty serializer and empty `output_keys`, like `QuoteSection`. It has no attributes to update.

`SectionPayload#extras_for` adds the list section case. The kit section show payload gains `items`, an array of item payloads in order, from `active_items`. Withheld kit sections stay title, subtitle, content type, and content id all nil, and do not include items. `KitSection` `output_keys` gains `:items` next to `:facts`, `:videos`, and `:locations`.

No new capability action. Adding a section is still `create_section` with `content_type: "RecordingStudioPresskits::ListSection"`. Removing it is still `remove_section`. Reordering sections is still `reorder_sections`. Creating and updating a line is the `ListItem` recordable API. Facts and quotes also have no reorder capability action. Item reorder stays on the UI order route. See open questions.

## Tests

Behavior lands with tests in the same change. Mirror facts.

Gem suite:

- `test/recording_studio_declarations_test.rb`. Declare both types. Parent of `ListSection` is `KitSection`. Parent of `ListItem` is `ListSection`. Neither is a root. `ListSection` is not allowed under the press kit or the workspace. Orderable on `ListSection` allows only `ListItem`. Trashable on both. Publishable and Duplicatable off both. Menu icon `list-bullet`. Label "List".
- `test/list_item_payload_test.rb` (new), beside `test/fact_payload_test.rb`. Payload shape, blank detail and url as nil, rejected http scheme left to the model test, withheld item, kit section `items` in order, trashed item omitted, empty section serializes `items: []`.
- `test/kit_download_test.rb` or the text-file coverage next to it. A list section contributes lines to `kit.txt` and no extra zip file. A trashed item and an empty list stay out.
- `test/recording_studio_presskits_test.rb`. Engine source includes `register_list_section`. README and the install guide mention `ListSection` once those docs are updated.

Dummy suite:

- `test/dummy/test/integration/list_section_test.rb`. `create_section!` writes the kit section and an empty list section in one transaction and does not write an item. Two list sections on one kit keep their own items. The editor adds, edits, reorders, and trashes an item. A bad URL re-renders. Trashing the section removes it from `KitQuery.sections_for` and leaves the rows. Public and preview HTML show the heading, the lines, and the link, and hide a section with no items.
- `test/dummy/test/integration/press_kit_ui_test.rb`. The picker row is List, the description is the new sentence, the icon is `list-bullet`.
- `test/dummy/test/integration/press_kit_download_test.rb`. Extend the manifest example with one list so `kit.txt` includes the line and a trashed line is absent.
- `test/dummy/config/initializers/recording_studio.rb` lists both types. `RecordingStudio.validate_recordable_declarations!` keeps passing.

Model specs worth a few assertions inside the integration test or a small gem test: `text` presence, `url` format, blank detail stored as nil.

No test should require `RecordingStudio::Lists::List` or `recording_studio_list_items`.

## Docs to update with the implementation

`README.md` gets a Lists paragraph next to Facts, in the same shape: two recordings, fields, editor, public page, order, trash. The picker sentence that lists type names and icons gains List / `list-bullet`. The install step that registers recordable types gains both class names.

`MIGRATION_NOTES.md` tells hosts to run the new migration and add the two types. There is no data move.

`CHANGELOG.md` and the gem version bump belong to the implementation branch, not to this proposal.

## Open questions

1. **Numbered lists.** This proposal is bullets only, in saved order. A ranking (tour dates, a top five) might want `1.` `2.` `3.` If that is in the first version, add `marker` on `ListSection` (`bullet` or `number`, default `bullet`), a Show as select on the content tab, and `permitted_attributes` of `[:marker]`. That is the facts `display_style` pattern, and it makes `ListSection` an updatable API type instead of an empty one. Leave it off until someone asks.

2. **How long is detail.** One plain string covers a year or a role. A filmography note that runs to a paragraph is a different field, closer to Text, and `kit.txt` would need a blank line between items. Stay with one optional line unless a real kit needs more.

3. **API reorder.** The UI can reorder items. Facts and quotes do not expose a reorder capability action, so this proposal does not either. An agent that can add items still cannot reorder them except by whatever Orderable already exposes on its own. Add `reorder_items` on `ListSection`, implemented with `QuoteOrder`, if agents need the same action as the editor.

4. **Link treatment.** The public page links the line. `kit.txt` prints the URL on its own line. The editor label is Link. No separate link label, and no `target` control. Say if the URL should be visible text next to the line on the public page as well.
