# frozen_string_literal: true

module RecordingStudioPresskits
  # Square corners zero Flatpack's radius tokens on the brand wrapper.
  # Blank and rounded leave the theme radii alone.
  class CornerStyle
    NAMES = %w[square rounded].freeze
    SQUARE_ATTRIBUTE = [
      "--radius-sm: 0",
      "--radius-md: 0",
      "--radius-lg: 0",
      "--radius-xl: 0",
      "--button-border-radius: 0"
    ].join("; ").freeze

    def self.normalize(value)
      raw = value.to_s.strip
      return if raw.blank?

      NAMES.find { |name| name.casecmp(raw).zero? } || :invalid
    end

    def self.square?(value)
      normalize(value) == "square"
    end

    def self.square_attribute
      SQUARE_ATTRIBUTE
    end
  end
end
