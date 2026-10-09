# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_presskits.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.216"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.4.0"
gem "recording_studio_accessible", "~> 0.13", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.13.0"
gem "recording_studio_admin", "~> 2.0", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.1.0"
gem "recording_studio_attachable", "~> 0.13", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.13.0"
gem "recording_studio_duplicatable", "~> 0.4", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.3"
gem "recording_studio_external_embed", "~> 0.1.1", github: "bowerbird-app/RecordingStudio_external_embed", tag: "v0.1.3"
gem "recording_studio_metrics", "~> 0.2", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.0"
gem "recording_studio_orderable", "~> 0.2", github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.5"
gem "recording_studio_publishable", "~> 0.6", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.6.0"
gem "recording_studio_trashable", "~> 0.6", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.6.0"
gem "recording_studio_video", "~> 0.1.0", github: "bowerbird-app/RecordingStudio_video", tag: "v0.1.0"

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
