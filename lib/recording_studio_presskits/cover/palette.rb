# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Palette
      DEFAULT_COLOR = "#1F2937"
      DEFAULT_COLORS = %w[#1F2937 #7C3AED #DB2777 #059669 #D97706].freeze
      NAMES = {
        "#1F2937" => "Ink",
        "#7C3AED" => "Violet",
        "#DB2777" => "Rose",
        "#059669" => "Forest",
        "#D97706" => "Honey"
      }.freeze

      def initialize(colors:, default_color:)
        @raw_colors = colors
        @raw_default = default_color
      end

      def any?
        @raw_colors == :any || @raw_colors.to_s == "any"
      end

      def colors
        return [] if any?

        normalized = Array(@raw_colors).filter_map { |color| Hex.normalize(color) }
        normalized.presence || DEFAULT_COLORS
      end

      def default_color
        Hex.normalize(@raw_default) || DEFAULT_COLOR
      end

      def include?(color)
        return true if any?

        hex = Hex.normalize(color)
        hex.present? && colors.include?(hex)
      end

      def label_for(color)
        hex = Hex.normalize(color)
        NAMES[hex] || hex
      end

      def options
        colors.map { |color| { label: label_for(color), value: color } }
      end
    end
  end
end
