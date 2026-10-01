# frozen_string_literal: true

require "test_helper"

class PresskitsCoverUrlTest < ActiveSupport::TestCase
  include RecordingStudioPresskits::ApplicationHelper

  test "uses a safe cover_image_url" do
    assert_equal "https://cdn.example/cover.jpg", presskits_cover_url_for(recording_with("https://cdn.example/cover.jpg"))
    assert_equal "/covers/spring.jpg", presskits_cover_url_for(recording_with("/covers/spring.jpg"))
  end

  test "drops blank unsafe and missing cover urls" do
    assert_nil presskits_cover_url_for(recording_with("javascript:alert(1)"))
    assert_nil presskits_cover_url_for(recording_with("data:text/html,hi"))
    assert_nil presskits_cover_url_for(recording_with("  "))
    assert_nil presskits_cover_url_for(recording_with(nil))
    assert_nil presskits_cover_url_for(Struct.new(:recordable).new(Object.new))
    assert_nil presskits_cover_url_for(nil)
  end

  private

  def recording_with(url)
    recordable = Struct.new(:cover_image_url).new(url)
    Struct.new(:recordable).new(recordable)
  end
end
