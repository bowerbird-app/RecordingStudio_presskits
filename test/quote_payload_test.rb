# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class QuotePayloadTest < ActiveSupport::TestCase
  test "includes body and name and keeps present role and organisation" do
    quote = RecordingStudioPresskits::Quote.new(
      body: "A line worth printing",
      name: "Ada",
      role: " Editor ",
      organisation: "Press"
    )

    assert_equal(
      { body: "A line worth printing", name: "Ada", role: "Editor", organisation: "Press" },
      RecordingStudioPresskits::Api::QuotePayload.for(quote)
    )
  end

  test "omits role and organisation when they are blank after strip" do
    quote = RecordingStudioPresskits::Quote.new(body: "", name: "", role: "  ", organisation: nil)

    assert_equal(
      { body: "", name: "" },
      RecordingStudioPresskits::Api::QuotePayload.for(quote)
    )
  end
end
