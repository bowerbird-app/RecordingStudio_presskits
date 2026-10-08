# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module RoundedDefaultLayoutAssertions
  def assert_rounded_default_layout
    assert_select "html[data-theme='rounded'][lang='#{I18n.locale}'][data-fp-copy]", count: 1
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_select "body[data-theme='rounded']", count: 1
    assert_includes response.body, "/assets/tailwind"
    assert_includes response.body, "/assets/flat_pack/variables"
    assert_includes response.body, "/assets/flat_pack/application"
  end

  def assert_page_nav_close(href: "/recording_studio_presskits/press_kits")
    assert_select ".flat-pack-page-nav [data-flat-pack--icon-name-value='x-mark']", count: 1
    assert_select "a[href='#{href}'][aria-label='Close']", count: 1
    refute_includes response.body, "Dummy host"
  end

  def assert_page_nav_without_access
    refute_includes response.body, "+ Access"
    refute_includes response.body, "Sign out"
    refute_includes response.body, ">Sign in<"
    refute_select ".flat-pack-page-nav a[href*='recording_studio_root_switchable']"
    refute_includes response.body, 'data-controller="recording-studio-root-switchable'
  end

  def assert_access_slot_only
    assert_select "a[href*='/accesses']", text: "+ Access"
    assert_includes response.body, "+ Access"
    assert_includes response.body, "/accesses"
    refute_includes response.body, "Sign out"
    refute_includes response.body, ">Sign in<"
    refute_select ".flat-pack-page-nav a[href*='recording_studio_root_switchable']"
    refute_includes response.body, 'data-controller="recording-studio-root-switchable'
  end

  def assert_blank_public_layout
    assert_select "html[data-theme='rounded'][lang='#{I18n.locale}'][data-fp-copy]", count: 1
    assert_select "body[data-presskits-blank-layout='true']", count: 1
    assert_select "body[data-theme='rounded']", count: 1
    assert_select "body[data-recording-studio-default-layout='true']", count: 0
    assert_select ".flat-pack-page-nav", count: 0
    assert_select "nav[aria-label='Page navigation']", count: 0
    refute_includes response.body, "recording_studio-publishable-layout"
    refute_includes response.body, "flat-pack--top-nav"
    refute_includes response.body, "Sign in"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "+ Access"
    assert_includes response.body, "/assets/tailwind"
    assert_includes response.body, "/assets/flat_pack/variables"
    assert_includes response.body, "/assets/flat_pack/application"
  end

end

class ActionDispatch::IntegrationTest
  include RoundedDefaultLayoutAssertions
end
