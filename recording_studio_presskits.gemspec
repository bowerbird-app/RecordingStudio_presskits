# frozen_string_literal: true

require_relative "lib/recording_studio_presskits/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_presskits"
  spec.version     = RecordingStudioPresskits::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_presskits"
  spec.summary     = "Press kit containers for Recording Studio hosts"
  spec.description = "A press kit is the container under a host root. Later addons supply the " \
                     "sections. Publish the kit, not each block."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "flat_pack", ">= 0.1.133"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
  spec.add_dependency "recording_studio_accessible", "~> 0.6"
  spec.add_dependency "recording_studio_admin", "~> 2.0"
  spec.add_dependency "recording_studio_duplicatable", "~> 0.4"
  spec.add_dependency "recording_studio_orderable", "~> 0.2"
  spec.add_dependency "recording_studio_trashable", "~> 0.4"
end
