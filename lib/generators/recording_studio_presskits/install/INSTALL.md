===============================================================================

RecordingStudioPresskits has been installed successfully!

The user slice is mounted at /recording_studio_presskits.

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioPresskits styles

To use the engine:
1. Start your Rails server
2. Visit http://localhost:3000/recording_studio_presskits
3. Add Orderable, Trashable, Duplicatable, Publishable, and Location; run their install and migrations. PressKit already opts in. KitSection already enables Location.
4. Register `RecordingStudioPublishable::Publishable` and mount Publishable at `/`. Run Location's install and migrations generators so the host owns `recording_studio_locations`.
5. Enable `section :press_kits` on your admin root after installing Recording Studio Admin 2.0.

===============================================================================
