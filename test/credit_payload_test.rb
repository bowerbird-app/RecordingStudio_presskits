# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class CreditPayloadTest < ActiveSupport::TestCase
  test "keeps the name and the present url and usual role" do
    credit = RecordingStudioPresskits::Credit.new(
      name: "Tom Ross",
      url: " https://example.com/tom ",
      usual_role: " Photography "
    )
    credit.validate

    assert_equal(
      { name: "Tom Ross", url: "https://example.com/tom", usual_role: "Photography" },
      RecordingStudioPresskits::Api::CreditPayload.for(credit)
    )
  end

  test "omits a blank url and usual role" do
    credit = RecordingStudioPresskits::Credit.new(name: "Vitra", url: "  ", usual_role: nil)
    credit.validate

    assert_equal({ name: "Vitra" }, RecordingStudioPresskits::Api::CreditPayload.for(credit))
  end
end
