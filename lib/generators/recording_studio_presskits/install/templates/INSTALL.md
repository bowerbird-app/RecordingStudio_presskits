RecordingStudioPresskits install complete.

Next steps:

1. Review config/initializers/recording_studio_presskits.rb and set any required options.
2. If you use environment-specific settings, create config/recording_studio_presskits.yml.
3. Install the engine migrations with `bin/rails generate recording_studio_presskits:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
6. Mount routes are added at the configured mount path. Adjust auth, layout, and current actor integration to match your host app.
7. Register `"RecordingStudioPresskits::PressKit"` next to your workspace type and keep `recording_studio_recordable(...)` on every configured type before running `RecordingStudio.validate_recordable_declarations!`.
