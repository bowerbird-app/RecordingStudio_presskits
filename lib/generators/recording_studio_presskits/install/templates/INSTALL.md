RecordingStudioPresskits install complete.

Next steps:

1. Review config/initializers/recording_studio_presskits.rb. Set `parent_root_type` to your host root class.
2. If you use environment-specific settings, create config/recording_studio_presskits.yml.
3. Install the engine migrations with `bin/rails generate recording_studio_presskits:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
6. Mount routes are added at the configured mount path. Point your host root at that slice, or redirect `/` there.
7. Register `"RecordingStudioPresskits::PressKit"` next to your workspace type and keep `recording_studio_recordable(...)` on every configured type before running `RecordingStudio.validate_recordable_declarations!`.
8. Add `recording_studio_orderable`, `recording_studio_trashable`, `recording_studio_duplicatable`, and `recording_studio_publishable`. Run each mixin's install and migrations generators. PressKit already opts in. Register `RecordingStudioPublishable::Publishable` in `recordable_types` and mount Publishable at `/`.
9. Install Recording Studio Admin 2.0, mount it under an admin root, and enable `section :press_kits`. Access is Accessible grants on that admin root, not `user.admin?`.
