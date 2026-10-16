# frozen_string_literal: true

require "test_helper"

class ControllerAuthTest < Minitest::Test
  def test_application_controller_uses_accessible_controller_auth
    path = File.expand_path("../app/controllers/recording_studio_presskits/application_controller.rb", __dir__)
    source = File.read(path)

    assert_includes source, "include RecordingStudioAccessible::ControllerAuth"
    assert_includes source, "recording_studio_auth("
    assert_includes source, "config: -> { RecordingStudioPresskits.configuration }"
    assert_includes source, "prefix: :presskits"

    protect_index = source.index("protect_from_forgery")
    include_index = source.index("include RecordingStudioAccessible::ControllerAuth")
    assert protect_index, "expected protect_from_forgery"
    assert include_index, "expected ControllerAuth include"
    assert_operator protect_index, :<, include_index

    refute_includes source, "def authenticate_presskits_actor!"
    refute_includes source, "def set_presskits_current_actor"
    refute_includes source, "def presskits_actor"
    refute_includes source, "def authorize_recording!"
    refute_includes source, "def current_presskits_root"
    refute_includes source, "def require_root!"
    refute_includes source, "RecordingStudioAccessible.authorized?"
  end

  def test_gem_and_dummy_pin_accessible_controller_auth_release
    root = File.expand_path("..", __dir__)
    gemfile = File.read(File.join(root, "Gemfile"))
    dummy = File.read(File.join(root, "test/dummy/Gemfile"))
    gemspec = File.read(File.join(root, "recording_studio_presskits.gemspec"))

    assert_includes gemfile, 'tag: "v0.19.0"'
    assert_includes gemfile, 'tag: "v0.11.0"'
    assert_includes gemfile, 'tag: "v0.4.3"'
    assert_includes dummy, 'tag: "v0.19.0"'
    assert_includes dummy, 'tag: "v0.11.0"'
    assert_includes dummy, 'tag: "v0.4.3"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.19"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_trashable", "~> 0.10"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.18"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_accessible", ">= 0.18.0"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_accessible", ">= 0.18.1"'
  end
end
