RecordingStudioPresskits install complete.

Next steps:

1. Review config/initializers/recording_studio_presskits.rb. Set `parent_root_type` to your host root class.
2. If you use environment-specific settings, create config/recording_studio_presskits.yml.
3. Install the engine migrations with `bin/rails generate recording_studio_presskits:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
6. Mount routes are added at the configured mount path. Point your host root at that slice, or redirect `/` there.
7. Register `"RecordingStudioPresskits::PressKit"`, `"RecordingStudioPresskits::KitSection"`, `"RecordingStudioPresskits::Text"`, `"RecordingStudioPresskits::Images"`, `"RecordingStudioPresskits::QuoteSection"`, `"RecordingStudioPresskits::Quote"`, `"RecordingStudioPresskits::CreditsSection"`, `"RecordingStudioPresskits::Credit"`, `"RecordingStudioPresskits::CreditLine"`, and `"RecordingStudio::Location::Location"` next to your workspace type. Keep `recording_studio_recordable(...)` on every configured type before running `RecordingStudio.validate_recordable_declarations!`.
8. Add `recording_studio_orderable`, `recording_studio_trashable`, `recording_studio_duplicatable`, `recording_studio_publishable`, `recording_studio_attachable`, and `recording_studio_location`. Run each mixin's install and migrations generators. PressKit already opts in. KitSection already enables Location. Register `RecordingStudioPublishable::Publishable` and `RecordingStudioAttachable::Attachment` in `recordable_types`. Mount Publishable at `/` and Attachable at `/recording_studio_attachable`. Run `bin/rails generate recording_studio_location:install` and `bin/rails generate recording_studio_location:migrations` so the host owns `recording_studio_locations`. Do not copy that table into Press Kits. Run `bin/rails active_storage:install` when those tables are missing. Pin `@rails/activestorage`, call `ActiveStorage.start()`, and eager-load `controllers/recording_studio_attachable`. Images uses Attachable 0.7. The section editor calls `attachment_collection_editor` for each photo's caption, credit, and alt text. Do not enable Attachable on PressKit.
9. Install Recording Studio Admin 2.0, mount it under an admin root, and enable `section :press_kits`. Access is Accessible grants on that admin root, not `user.admin?`.
10. Pin the press kit section-order controller. FlatPack list-orderable drags the rows. This controller saves the drop:

```ruby
pin_all_from RecordingStudioPresskits::Engine.root.join("app/javascript/recording_studio_presskits/controllers"), under: "controllers/recording_studio_presskits", to: "recording_studio_presskits/controllers"
```
