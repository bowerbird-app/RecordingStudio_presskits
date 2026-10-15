# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit
    module BrandAttributes
      extend ActiveSupport::Concern

      included do
        validate :branding_must_be_usable
      end

      def brand_color=(value)
        assign_brand(:brand_color, BrandStyle.normalize_color(value), :@brand_color_invalid)
      end

      def font_family=(value)
        assign_brand(:font_family, BrandStyle.normalize_font(value), :@font_family_invalid)
      end

      def text_color=(value)
        assign_brand(:text_color, BrandStyle.normalize_color(value), :@text_color_invalid)
      end

      def corner_style=(value)
        assign_brand(:corner_style, CornerStyle.normalize(value), :@corner_style_invalid)
      end

      private

      def assign_brand(attribute, normalized, flag)
        if normalized == :invalid
          instance_variable_set(flag, true)
          return
        end

        instance_variable_set(flag, false)
        self[attribute] = normalized
      end

      def branding_must_be_usable
        errors.add(:base, "Brand colour must be a hex colour.") if @brand_color_invalid
        errors.add(:base, "Font must be sans, serif, or mono.") if @font_family_invalid
        errors.add(:base, "Button text must be a hex colour.") if @text_color_invalid
        errors.add(:base, "Corners must be square or rounded.") if @corner_style_invalid
      end
    end
  end
end
