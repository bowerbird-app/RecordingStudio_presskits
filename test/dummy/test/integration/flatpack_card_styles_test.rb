# frozen_string_literal: true

require "test_helper"

class FlatpackCardStylesTest < ActionDispatch::IntegrationTest
  test "removed structural card styles map onto the Flatpack 0.1.237 card API" do
    assert_includes FlatPack::Card::Component.ancestors, RecordingStudioPresskits::FlatpackCardStyles

    outlined = render_card(style: :outlined)
    assert_includes outlined, "border-2"
    assert_includes outlined, "[background:var(--card-style-default-background)]"
    refute_includes outlined, "shadow-[var(--shadow-md)]"

    elevated = render_card(style: :elevated)
    assert_includes elevated, "shadow-[var(--shadow-md)]"
    assert_includes elevated, "border"

    flat = render_card(style: :flat)
    assert_includes flat, "[background:var(--card-style-shaded-background)]"
    refute_includes flat, "border-2"
    refute_includes flat, "border border-[var(--card-border-color)]"

    kept = render_card(style: :outlined, border: :none)
    refute_includes kept, "border-2"
  end

  private

  def render_card(**options)
    ApplicationController.renderer.render(FlatPack::Card::Component.new(**options)) { "Harbour" }
  end
end
