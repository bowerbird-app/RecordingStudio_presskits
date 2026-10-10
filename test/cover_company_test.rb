# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/cover/company"

class CoverCompanyTest < Minitest::Test
  def test_lookup_is_blank_without_a_recording
    assert_nil RecordingStudioPresskits::Cover::Company.recording_for(nil)
    assert_nil RecordingStudioPresskits::Cover::Company.name_for(nil)
  end
end
