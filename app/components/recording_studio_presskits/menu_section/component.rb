# frozen_string_literal: true

module RecordingStudioPresskits
  class MenuSection
    class Component < ViewComponent::Base
      # Tailwind scans these literals:
      # "m-0" "grid" "list-none" "p-0" "gap-2" "gap-3" "grid-cols-1"
      # "grid-cols-[repeat(auto-fill,minmax(14rem,1fr))]"
      # "flex" "min-w-0" "items-center" "w-full" "flex-1"
      GRID_CLASSES = "m-0 grid list-none grid-cols-[repeat(auto-fill,minmax(14rem,1fr))] gap-3 p-0"
      LIST_CLASSES = "m-0 grid list-none grid-cols-1 gap-2 p-0"
      ITEM_CLASSES = "flex min-w-0 items-center gap-2"
      # "line-clamp-2" "min-w-0" "text-left"
      LINK_CLASSES = "w-full min-w-0 flex-1 [&>span]:line-clamp-2 [&>span]:min-w-0 [&>span]:text-left"

      Entry = Struct.new(:button, :badge, keyword_init: true)

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

      def list_classes
        menu.layout == "list" ? LIST_CLASSES : GRID_CLASSES
      end

      def item_classes
        ITEM_CLASSES
      end

      def heading_anchor_id
        RecordingStudioPresskits.section_anchor_id(kit_section)
      end

      private

      def entry_for(section)
        Entry.new(button: link_button(section), badge: count_badge(section))
      end

      def link_button(section)
        heading = RecordingStudioPresskits.section_heading(section)
        FlatPack::Button::Component.new(**link_options(section, heading))
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
          class: LINK_CLASSES,
          title: heading,
          aria: (menu.label_overridden?(section) ? { label: heading } : nil)
        }.compact
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
