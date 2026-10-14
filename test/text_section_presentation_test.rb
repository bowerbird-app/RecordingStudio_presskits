# frozen_string_literal: true

require "test_helper"

class TextSectionPresentationTest < Minitest::Test
  def test_public_text_template_uses_the_theme_token_and_reserves_the_copy_slot
    root = File.expand_path("..", __dir__)
    show = File.read("#{root}/app/components/recording_studio_presskits/text/component.html.erb")
    ruby = File.read("#{root}/app/components/recording_studio_presskits/text/component.rb")
    heading_dir = "#{root}/app/components/recording_studio_presskits/press_kits"
    heading = File.read("#{heading_dir}/text_section_heading_component.html.erb")
    heading_ruby = File.read("#{heading_dir}/text_section_heading_component.rb")
    text_model = File.read("#{root}/app/models/recording_studio_presskits/text.rb")
    frame = File.read("#{root}/app/components/recording_studio_presskits/press_kits/section_frame_component.html.erb")
    frame_ruby = File.read("#{root}/app/components/recording_studio_presskits/press_kits/section_frame_component.rb")
    inline = File.read("#{root}/app/components/recording_studio_presskits/text/inline_component.html.erb")
    editor = File.read("#{root}/app/components/recording_studio_presskits/press_kits/editable_section_component.rb")
    controller = File.read("#{root}/app/javascript/recording_studio_presskits/controllers/text_collapse_controller.js")

    assert_includes ruby, "text-[var(--surface-muted-content-color)]"
    assert_includes ruby, "text-base"
    assert_includes ruby, "leading-7"
    assert_includes ruby, "max-w-[65ch]"
    assert_includes ruby, "[&_p+p]:mt-5"
    assert_includes ruby, "max-h-[14rem]"
    assert_includes ruby, "from-[var(--card-background-color)]"
    refute_includes show, "ProseMirror"
    refute_includes show, "flat-pack-richtext"
    assert_includes show, "recording-studio-presskits--text-collapse"
    assert_includes show, 'aria: { expanded: "false"'
    assert_includes show, "show_more_label"
    assert_includes show, "style: :default"
    refute_includes show, "style: :ghost"
    assert_includes heading, "data-presskits-text-copy-slot"
    assert_includes heading, "justify-between"
    assert_includes heading, "copy_button"
    assert_includes heading_ruby, "FlatPack::CopyButton::Component"
    assert_includes heading_ruby, "style: :secondary"
    assert_includes heading_ruby, "size: :sm"
    assert_includes heading_ruby, 'icon: "clipboard-document"'
    assert_includes heading_ruby, "recording_studio_presskits.text.copy"
    assert_includes text_model, "def self.clipboard_text"
    assert_includes text_model, 'gsub(/\n{3,}/, "\n\n")'
    assert_includes heading_ruby, "def clipboard_text_from_section"
    assert_includes heading_ruby, "Text.clipboard_text"
    refute_includes inline, "CopyButton"
    refute_includes inline, "flat-pack--clipboard"
    assert_includes heading_ruby, "font-bold"
    assert_includes heading_ruby, "text-[2rem]"
    assert_includes heading_ruby, "text-[var(--surface-content-color)]"
    assert_includes frame, "text_section?"
    assert_includes frame, "text_heading"
    assert_includes frame, "heading_component"
    assert_includes frame, "gap-7"
    assert_includes frame_ruby, "def text_section?"
    assert_includes frame_ruby, "SectionHeadingComponent.new"
    assert_includes inline, "mode: :rich"
    refute_includes inline, "text-collapse"
    refute_includes inline, "show_more"
    assert_includes editor, "TextSectionHeadingComponent::TITLE_CLASSES"
    assert_includes editor, "return unless text_section?"
    assert_includes controller, "aria-expanded"
    assert_includes controller, "lessLabel"
    assert_includes controller, "max-h-[14rem]"
    assert_includes ruby, "VISIBLE_LINES = 8"
    assert_includes ruby, "COLLAPSE_AFTER = 700"
  end
end
