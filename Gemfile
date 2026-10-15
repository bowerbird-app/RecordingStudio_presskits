# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_presskits.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.239"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.5.0"
gem "recording_studio_accessible", "~> 0.18", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.18.0"
gem "recording_studio_admin", "~> 2.0", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.2.0"
gem "recording_studio_attachable", "~> 0.15", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.15.0"
gem "recording_studio_company", "~> 0.4", github: "bowerbird-app/RecordingStudio_company", tag: "v0.4.0"
gem "recording_studio_downloadable", "~> 0.4", github: "bowerbird-app/RecordingStudio_downloadable", tag: "v0.4.0"
gem "recording_studio_duplicatable", "~> 0.5", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.5.0"
# Mirrors bowerbird-app/RecordingStudio_embargo v0.1.0 (commit 8d1e787).
# Switch to the git source once CI can reach the private repo:
# gem "recording_studio_embargo", git: "https://github.com/bowerbird-app/RecordingStudio_embargo.git", tag: "v0.1.0"
gem "recording_studio_embargo", path: "vendor/gems/recording_studio_embargo"
gem "recording_studio_external_embed", "~> 0.1.1", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.4"
gem "recording_studio_lists", "~> 0.5", github: "bowerbird-app/RecordingStudio_lists", tag: "v0.5.0"
gem "recording_studio_location", "~> 0.4", github: "bowerbird-app/RecordingStudio_location", tag: "v0.6.0"
gem "recording_studio_metrics", "~> 0.3", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.3.1"
gem "recording_studio_orderable", "~> 0.3", github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.3.0"
gem "recording_studio_publishable", "~> 0.8", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.8.0"
gem "recording_studio_trashable", "~> 0.10", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.10.1"
gem "recording_studio_video", "~> 0.2.0", github: "bowerbird-app/RecordingStudio_video", tag: "v0.2.0"

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
