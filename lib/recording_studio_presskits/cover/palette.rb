# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Palette
      AUTO_VALUE = "auto"
      DEFAULT_COLOR = "#1F2937"
      DEFAULT_COLORS = %w[#1F2937 #7C3AED #DB2777 #059669 #D97706].freeze
      DEFAULT_TEXT_COLORS = %w[#F8FAFC #111827 #E5E7EB #6B7280].freeze
      NAMES = {
        "#1F2937" => "Ink",
        "#7C3AED" => "Violet",
        "#DB2777" => "Rose",
        "#059669" => "Forest",
        "#D97706" => "Honey",
        "#F8FAFC" => "Snow",
        "#111827" => "Ink",
        "#E5E7EB" => "Cloud",
        "#6B7280" => "Slate"
      }.freeze

      def initialize(colors:, default_color: nil, fallback_colors: DEFAULT_COLORS)
        @raw_colors = colors
        @raw_default = default_color
        @fallback_colors = fallback_colors
      end

      def any?
        @raw_colors == :any || @raw_colors.to_s == "any"
      end

      def colors
        return [] if any?

        normalized = Array(@raw_colors).filter_map { |color| Hex.normalize(color) }
        normalized.presence || Array(@fallback_colors)
      end

      def default_color
        Hex.normalize(@raw_default) || Hex.normalize(Array(@fallback_colors).first) || DEFAULT_COLOR
      end

      def include?(color)
        return true if any?
        return true if auto?(color)

        hex = Hex.normalize(color)
        hex.present? && colors.include?(hex)
      end

      def label_for(color)
        return "Auto" if auto?(color)

        hex = Hex.normalize(color)
        NAMES[hex] || hex
      end

      def options(auto: false)
        named = colors.map { |color| { label: label_for(color), value: color } }
        return named unless auto

        [{ label: "Auto", value: AUTO_VALUE }] + named
      end

      def auto?(color)
        color.to_s.strip.downcase == AUTO_VALUE
      end
    end
  end
end
