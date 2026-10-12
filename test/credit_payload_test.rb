# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class CreditLinePayloadTest < ActiveSupport::TestCase
  test "keeps the name and the present role and url" do
    line = line_recording(name: "Tom Ross", role: " Photography ", url: " https://example.com/tom ")

    assert_equal(
      { name: "Tom Ross", role: "Photography", url: "https://example.com/tom" },
      RecordingStudioPresskits::Api::CreditLinePayload.for(line)
    )
  end

  test "omits a blank role and url" do
    line = line_recording(name: "Vitra", role: "  ", url: nil)

    assert_equal({ name: "Vitra" }, RecordingStudioPresskits::Api::CreditLinePayload.for(line))
  end

  test "is empty without a recording" do
    assert_equal({}, RecordingStudioPresskits::Api::CreditLinePayload.for(nil))
  end

  private

  def line_recording(name:, role:, url:)
    recordable = RecordingStudioPresskits::CreditLine.new(name: name, role: role, url: url)
    recordable.validate
    Struct.new(:recordable).new(recordable)
  end
end
