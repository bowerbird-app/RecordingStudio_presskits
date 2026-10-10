# frozen_string_literal: true

require "test_helper"
require "recording_studio_presskits/kit_location"

class KitLocationTest < Minitest::Test
  def test_lookup_is_blank_without_a_parent
    assert_nil RecordingStudioPresskits::KitLocation.recording_for(nil)
    assert_nil RecordingStudioPresskits::KitLocation.recordable_for(nil)
  end

  def test_blank_when_every_attribute_is_empty
    assert RecordingStudioPresskits::KitLocation.blank?({ title: "", locality: nil })
    refute RecordingStudioPresskits::KitLocation.blank?({ title: "Harbour Gallery" })
  end
end
