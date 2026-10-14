# frozen_string_literal: true

module RecordingStudioPresskits
  # Heading fragment ids for a kit. The first section in kit order keeps the
  # parameterized heading. Later collisions become heading-2, heading-3, …
  module SectionAnchor
    def section_anchor_id(section_recording)
      return if section_recording.blank?

      anchors_for(section_recording)[section_recording.id] || anchor_base(section_recording)
    end

    private

    def anchors_for(section_recording)
      kit = press_kit_parent(section_recording)
      return {} if kit.blank?

      assign_anchors(KitQuery.sections_for(kit).to_a)
    end

    def press_kit_parent(section_recording)
      parent = section_recording.parent_recording
      return unless parent&.recordable.is_a?(PressKit)

      parent
    end

    def assign_anchors(sections)
      taken = {}
      sections.each_with_object({}) do |section, map|
        map[section.id] = unique_anchor(anchor_base(section), taken)
      end
    end

    def unique_anchor(base, taken)
      candidate = base
      suffix = 2
      while taken[candidate]
        candidate = "#{base}-#{suffix}"
        suffix += 1
      end
      taken[candidate] = true
      candidate
    end

    def anchor_base(section_recording)
      section_heading(section_recording).to_s.parameterize.presence || "section-#{section_recording.id}"
    end
  end
end
