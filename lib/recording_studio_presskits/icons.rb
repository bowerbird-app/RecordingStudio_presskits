# frozen_string_literal: true

module RecordingStudioPresskits
  # Names Flatpack already paints. The set is the outline bank in flat_pack/heroicons.js.
  # Aliases such as "search" follow FlatPack::Shared::IconComponent::NAME_MAP.
  module Icons
    module_function

    def names
      @names ||= outline_names
    end

    def known?(name)
      canonical(name).present?
    end

    def canonical(name)
      raw = name.to_s.strip.tr("_", "-")
      return if raw.blank?

      mapped = aliases.fetch(raw, raw)
      mapped if names.include?(mapped)
    end

    def choices
      names.map { |name| [choice_label(name), name] }
    end

    def aliases
      FlatPack::Shared::IconComponent::NAME_MAP
    end

    def choice_label(name)
      name.tr("-", " ")
    end

    def outline_names
      source = File.read(heroicons_path)
      outline = source.split("export const solid", 2).first.to_s
      outline.scan(/^\s+"([^"]+)":/).flatten.freeze
    end

    def heroicons_path
      FlatPack::Engine.root.join("app/javascript/flat_pack/heroicons.js")
    end
  end
end
