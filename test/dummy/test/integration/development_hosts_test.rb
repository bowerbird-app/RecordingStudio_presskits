# frozen_string_literal: true

require "test_helper"

class DevelopmentHostsTest < ActiveSupport::TestCase
  PREVIEW_HOST = "1b0bd7783c2367cdfe03-pod-gx7ivgr2q5fd5aipbrx7zulkam-3000.us5p.cursorvm.com"

  test "development allows cursor preview hosts" do
    source = Rails.root.join("config/environments/development.rb").read
    assert_includes source, "config.hosts << /.*\\.cursorvm\\.com/"
    assert_includes source, 'if ENV["CURSOR_AGENT"].present?'
    assert_includes source, "forgery_protection_origin_check = false"

    permissions = ActionDispatch::HostAuthorization::Permissions.new([/.*\.cursorvm\.com/])
    assert permissions.allows?(PREVIEW_HOST)
    assert permissions.allows?("#{PREVIEW_HOST}:443")
    refute permissions.allows?("evil.example")
    refute permissions.allows?("cursorvm.com.evil.example")
    refute permissions.allows?("notcursorvm.com")
  end
end
