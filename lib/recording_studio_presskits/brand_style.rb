# frozen_string_literal: true

module RecordingStudioPresskits
  # Same tokens as RecordingStudioPressCenters::Branding. Used when that
  # class is not loaded, and as the font stacks for the kit style controls.
  class BrandStyle
    LIGHT = Cover::Contrast::LIGHT
    DARK = Cover::Contrast::DARK
    DEFAULT_COLOR = "#333333"
    DEFAULT_FONT = "sans"
    FONTS = %w[sans serif mono].freeze

    SWATCH_CSS = {
      "sans" => "ui-sans-serif, system-ui, sans-serif",
      "serif" => "ui-serif, Georgia, serif",
      "mono" => "ui-monospace, SFMono-Regular, monospace"
    }.freeze

    FONT_CSS = {
      "sans" => "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif",
      "serif" => "ui-serif, Georgia, Cambria, Times New Roman, serif",
      "mono" => "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
    }.freeze

    # Flatpack resolves hover, the focus ring, and the primary button aliases on
    # the theme root. A child that only sets --color-primary keeps Flatpack's
    # pressed, hovered, and focused colours. These aliases have to sit on the
    # same element as --color-primary. Relative colour keeps the same lightness
    # step Flatpack uses (l - 0.1, and a further step for the pressed fill).
    TOKEN_ALIASES = [
      "--color-primary-hover: oklch(from var(--color-primary) calc(l - 0.1) c h)",
      "--color-primary-active: oklch(from var(--color-primary) calc(l - 0.16) c h)",
      "--button-primary-background-color: var(--color-primary)",
      "--button-primary-hover-background-color: var(--color-primary-hover)",
      "--button-primary-active-background-color: var(--color-primary-active)",
      "--button-primary-active-border-color: var(--color-primary-active)",
      "--button-primary-text-color: var(--color-primary-text)",
      "--button-primary-border-color: var(--color-primary)",
      "--color-ring: var(--color-primary)",
      "--button-focus-ring-color: var(--color-primary)"
    ].freeze

    # Editor controls that sit inside a branded preview. Restores Flatpack's
    # primary from the theme's brand knobs, which the kit style does not touch.
    NEUTRAL_CLASS = "presskits-neutral-controls"

    def self.swatch_options
      [
        ["Sans", SWATCH_CSS.fetch("sans")],
        ["Serif", SWATCH_CSS.fetch("serif")],
        ["Mono", SWATCH_CSS.fetch("mono")]
      ]
    end

    def self.normalize_color(value)
      raw = value.to_s.strip
      return if raw.blank?

      Cover::Hex.normalize(raw) || :invalid
    end

    def self.normalize_font(value)
      raw = value.to_s.strip
      return if raw.blank?

      key = SWATCH_CSS.keys.find { |name| name.casecmp(raw).zero? }
      return key if key

      [SWATCH_CSS, FONT_CSS].each do |table|
        match = table.find { |_name, css| css.casecmp(raw).zero? }
        return match.first if match
      end

      :invalid
    end

    def self.text_on(background)
      Cover::Contrast.text_on(background)
    end

    def self.font_css_for(font_family)
      FONT_CSS[font_family.to_s]
    end

    def self.swatch_css_for(font_family)
      SWATCH_CSS[font_family.to_s] || SWATCH_CSS.fetch(DEFAULT_FONT)
    end

    # Hover, pressed fill, and focus ring. Pair with --color-primary on the
    # same element. The card theme cannot carry the relative colour: Flatpack
    # only accepts a plain colour in that hash.
    def self.button_state_attribute
      TOKEN_ALIASES.join("; ")
    end

    def self.neutral_style_attribute
      [
        "--color-primary: oklch(var(--brand-lightness) var(--brand-chroma) var(--brand-hue))",
        "--color-primary-text: #fff",
        *TOKEN_ALIASES
      ].join("; ")
    end

    def initialize(brand_color:, font_family:)
      @brand_color = brand_color.presence
      @font_family = font_family.presence
    end

    attr_reader :brand_color, :font_family

    def resolved_text_color
      return if brand_color.blank?

      self.class.text_on(brand_color)
    end

    def font_css
      self.class.font_css_for(font_family)
    end

    def style_attribute
      parts = color_declarations
      parts << "font-family: #{font_css}" if font_css
      parts.join("; ").presence
    end

    private

    def color_declarations
      return [] if brand_color.blank? || resolved_text_color.blank?

      ["--color-primary: #{brand_color}", "--color-primary-text: #{resolved_text_color}", *TOKEN_ALIASES]
    end
  end
end
