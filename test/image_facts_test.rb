# frozen_string_literal: true

require "test_helper"

class ImageFactsTest < Minitest::Test
  def test_caption_uses_the_name_and_a_reduced_ratio
    facts = RecordingStudioPresskits::ImageFacts.new(attachment(width: 4800, height: 6000, name: "Hero — Pendant"))

    assert_equal "Hero — Pendant", facts.name
    assert_equal "JPG · 4800×6000 · 4:5", facts.meta
    refute facts.respond_to?(:caption)
  end

  def test_wide_frames_use_16_9
    facts = RecordingStudioPresskits::ImageFacts.new(attachment(width: 1600, height: 900, name: "Studio"))

    assert_equal "JPG · 1600×900 · 16:9", facts.meta
  end

  def test_an_odd_frame_keeps_the_greatest_common_divisor
    facts = RecordingStudioPresskits::ImageFacts.new(attachment(width: 64, height: 28, name: "Cover"))

    assert_equal "JPG · 64×28 · 16:7", facts.meta
  end

  def test_credit_line_uses_the_brand
    line = RecordingStudioPresskits::ImagesCredit.line_for("Harbour Studio")

    assert_equal "High-resolution photography, free for editorial use. Please credit “Harbour Studio”.", line
  end

  private

  def attachment(width:, height:, name:)
    blob = Struct.new(:metadata).new({ "width" => width, "height" => height })
    file = Struct.new(:blob) do
      def attached?
        true
      end
    end
    Struct.new(:name, :content_type, :file).new(name, "image/jpeg", file.new(blob))
  end
end
