# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_presskits.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.135"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", "~> 0.10", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.10.0"
gem "recording_studio_admin", "~> 2.0", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.0"
gem "recording_studio_attachable", "~> 0.7", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.7.0"
gem "recording_studio_duplicatable", "~> 0.4", github: "bowerbird-app/RecordingStudio_duplicatable", tag: "0.4.0"
gem "recording_studio_orderable", "~> 0.2", github: "bowerbird-app/RecordingStudio_orderable", tag: "0.2.0"
gem "recording_studio_publishable", "~> 0.3", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.1"
gem "recording_studio_trashable", "~> 0.4", github: "bowerbird-app/RecordingStudio_trashable", tag: "0.4.0"

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
