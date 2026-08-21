# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module RoundedDefaultLayoutAssertions
  def assert_rounded_default_layout
    assert_select "html[data-theme='rounded']", count: 1
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_select "body[data-theme='rounded']", count: 1
    assert_includes response.body, "/assets/tailwind"
    assert_includes response.body, "/assets/flat_pack/variables"
  end
end

class ActionDispatch::IntegrationTest
  include RoundedDefaultLayoutAssertions
end
