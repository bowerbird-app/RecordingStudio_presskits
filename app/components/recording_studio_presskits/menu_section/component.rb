# frozen_string_literal: true

module RecordingStudioPresskits
  class MenuSection
    class Component < ViewComponent::Base
      GRID_MIN_ITEM_WIDTH = "14rem"

      Entry = Struct.new(:button_options, :badge, keyword_init: true)

      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        entries.any?
      end

      def entries
        @entries ||= linked_sections.map { |section| entry_for(section) }
      end

      def collection_options
        options = {
          as: :nav,
          label: menu_heading,
          layout: collection_layout,
          data: { presskits_menu: true }
        }
        options[:gap] = :sm if list_layout?
        options[:min_item_width] = GRID_MIN_ITEM_WIDTH unless list_layout?
        options
      end

      private

      def entry_for(section)
        heading = RecordingStudioPresskits.section_heading(section)
        Entry.new(button_options: link_options(section, heading), badge: count_badge(section))
      end

      def link_options(section, heading)
        options = base_link_options(section, heading)
        icon = section_icon(section)
        options[:icon] = icon if icon.present?
        options
      end

      def base_link_options(section, heading)
        {
          text: menu.link_label(section, heading),
          href: "##{RecordingStudioPresskits.section_anchor_id(section)}",
          style: :default,
          align: :start,
          lines: 2,
          title: heading,
          aria: (menu.label_overridden?(section) ? { label: heading } : nil)
        }.compact
      end

      def collection_layout
        list_layout? ? :stack : :grid
      end

      def list_layout?
        menu.layout == "list"
      end

      def menu_heading
        RecordingStudioPresskits.section_heading(kit_section)
      end

      def count_badge(section)
        return unless menu.show_counts?

        PressKits::SectionCountBadge.for(section_content(section), accessible: true)
      end

      def section_icon(section)
        return unless menu.show_icons?

        recordable = section_content(section)&.recordable
        return if recordable.blank?

        recordable.class.try(:section_menu_icon)
      end

      def linked_sections
        sibling_sections.select { |section| linkable?(section) }
      end

      def linkable?(section)
        return false if section.id == kit_section&.id
        return false if menu_content?(section)
        return false if menu.hidden_section?(section)

        PressKits::SectionFrameComponent.new(section_recording: section).content_visible?
      end

      def menu_content?(section)
        section_content(section)&.recordable.is_a?(MenuSection)
      end

      def sibling_sections
        kit = kit_recording
        return [] if kit.blank?

        KitQuery.sections_for(kit).to_a
      end

      def section_content(section)
        KitQuery.section_content(section)
      end

      def menu
        @recording.recordable
      end

      def kit_section
        @recording.parent_recording
      end

      def kit_recording
        kit_section&.parent_recording
      end
    end
  end
end
