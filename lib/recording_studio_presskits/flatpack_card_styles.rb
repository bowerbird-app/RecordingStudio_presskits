# frozen_string_literal: true

module RecordingStudioPresskits
  # Flatpack 0.1.237 dropped the structural card styles. Location and Trashable
  # still pass those names. Map each one onto the colour, border, shadow, and
  # hover the old style used, and leave an explicit border, shadow, or hover alone.
  module FlatpackCardStyles
    REPLACEMENTS = {
      outlined: { style: :default, border: :strong },
      elevated: { style: :default, shadow: :md },
      flat: { style: :shaded, border: :none },
      interactive: { style: :default, hover: :strong },
      list: { style: :default, hover: :subtle }
    }.freeze

    def initialize(style: :default, shadow: :none, border: :default, hover: :none, **rest)
      style, shadow, border, hover = rewritten(style, shadow, border, hover)
      # Bare super would keep the caller's style name. These are the mapped keywords.
      super(style: style, shadow: shadow, border: border, hover: hover, **rest) # rubocop:disable Style/SuperArguments
    end

    private

    def rewritten(style, shadow, border, hover)
      replacement = REPLACEMENTS[style.to_sym]
      return [style, shadow, border, hover] unless replacement

      [
        replacement.fetch(:style),
        pick(replacement, :shadow, shadow, :none),
        pick(replacement, :border, border, :default),
        pick(replacement, :hover, hover, :none)
      ]
    end

    def pick(replacement, key, given, unchanged)
      return given unless replacement.key?(key) && given == unchanged

      replacement.fetch(key)
    end
  end
end
