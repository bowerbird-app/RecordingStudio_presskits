RecordingStudioPresskits install complete.

Next steps:

1. Review config/initializers/recording_studio_presskits.rb. Set `parent_root_type` to your host root class.
2. If you use environment-specific settings, create config/recording_studio_presskits.yml.
3. Install the engine migrations with `bin/rails generate recording_studio_presskits:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
6. Mount routes are added at the configured mount path. Point your host root at that slice, or redirect `/` there.
7. Register `"RecordingStudioPresskits::PressKit"`, `"RecordingStudioPresskits::KitSection"`, `"RecordingStudioPresskits::Text"`, `"RecordingStudioPresskits::Images"`, `"RecordingStudioPresskits::QuoteSection"`, `"RecordingStudioPresskits::Quote"`, `"RecordingStudioPresskits::FactsSection"`, `"RecordingStudioPresskits::Fact"`, `"RecordingStudioPresskits::CreditsSection"`, `"RecordingStudioPresskits::Credit"`, and `"RecordingStudioPresskits::CreditLine"` next to your workspace type. Keep `recording_studio_recordable(...)` on every configured type before running `RecordingStudio.validate_recordable_declarations!`.
8. Add `recording_studio_orderable`, `recording_studio_trashable`, `recording_studio_duplicatable`, `recording_studio_publishable`, `recording_studio_downloadable`, `recording_studio_attachable`, `recording_studio_company`, and `recording_studio_location`. Run each mixin's install and migrations generators, including Accessible's AccessConstraint / AccessRule migrations. PressKit already opts into Location, LibraryPlacement, and Downloadable (`:"presskits.kit_download"`). Company and the image library are host opt-ins on the root (`Companies.to(allow: :one)`, `ImageLibrary.to`). Register `RecordingStudioPublishable::Publishable`, `RecordingStudioAttachable::Attachment`, `RecordingStudioAttachable::Library`, `RecordingStudioAttachable::Placement`, `RecordingStudioCompany::Company`, and `RecordingStudio::Location::Location` in `recordable_types`. Mount Publishable at `/`, Downloadable at `/recording_studio_downloadable`, Attachable at `/recording_studio_attachable`, Company at `/recording_studio_company`, and Location at `/recording_studio_location`. Run `bin/rails active_storage:install` when those tables are missing. Pin `@rails/activestorage`, call `ActiveStorage.start()`, and eager-load `controllers/recording_studio_attachable`, `controllers/recording_studio_location`, and `controllers/recording_studio_downloadable`. Images sections hold library placements. The kit cover image is a library placement, picked with Attachable's placements screen. Do not enable Attachable on PressKit. Hosts overwrite `config.action_audiences[:"presskits.kit_download"]` when the default public audience should differ. Kit editors change who may download from **Downloads** on the kit toolbar.
9. Install Recording Studio Admin 2.0, mount it under an admin root, and enable `section :press_kits`. Access is Accessible grants on that admin root, not `user.admin?`.
10. Pin the press kit section-order controller. FlatPack list-orderable drags the rows. This controller saves the drop:

```ruby
pin_all_from RecordingStudioPresskits::Engine.root.join("app/javascript/recording_studio_presskits/controllers"), under: "controllers/recording_studio_presskits", to: "recording_studio_presskits/controllers"
```
