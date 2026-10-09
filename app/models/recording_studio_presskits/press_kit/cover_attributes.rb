# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKit
    module CoverAttributes
      extend ActiveSupport::Concern

      AUTO_COVER_TEXT = RecordingStudioPresskits::Cover::Palette::AUTO_VALUE

      included do
        validate :cover_color_must_be_hex
        validate :cover_color_must_be_allowed, if: :validate_cover_palette?
        validate :cover_text_color_must_be_hex
        validate :cover_text_color_must_be_allowed, if: :validate_cover_text_palette?
      end

      def cover_color=(value)
        remember_cover_color
        @cover_color_assigned = true
        super
      end

      def cover_text_color=(value)
        remember_cover_text_color
        @cover_text_color_assigned = true
        super(auto_cover_text?(value) ? nil : value)
      end

      def resolved_cover_style
        cover_style.presence || "color"
      end

      def resolved_cover_color
        RecordingStudioPresskits::Cover::Hex.normalize(cover_color) || RecordingStudioPresskits.default_cover_color
      end

      def resolved_cover_text_color
        RecordingStudioPresskits::Cover::Hex.normalize(cover_text_color) || overlay_text_color
      end

      def overlay_text_color
        RecordingStudioPresskits::Cover::Contrast.text_on(resolved_cover_color)
      end

      def cover_text_low_contrast?
        RecordingStudioPresskits::Cover::Contrast.low_contrast?(resolved_cover_color, resolved_cover_text_color)
      end

      private

      def normalize_cover
        assigned = cover_assignment_flags
        self.cover_style = cover_style.to_s.strip.presence
        normalize_hex_attribute(:cover_color)
        normalize_hex_attribute(:cover_text_color)
        restore_cover_assignment_flags(assigned)
      end

      def cover_assignment_flags
        {
          color: [@cover_color_assigned, @stored_cover_color_before_assign],
          text: [@cover_text_color_assigned, @stored_cover_text_color_before_assign]
        }
      end

      def restore_cover_assignment_flags(flags)
        @cover_color_assigned, @stored_cover_color_before_assign = flags[:color]
        @cover_text_color_assigned, @stored_cover_text_color_before_assign = flags[:text]
      end

      def remember_cover_color
        return if instance_variable_defined?(:@stored_cover_color_before_assign)

        @stored_cover_color_before_assign = cover_color
      end

      def remember_cover_text_color
        return if instance_variable_defined?(:@stored_cover_text_color_before_assign)

        @stored_cover_text_color_before_assign = cover_text_color
      end

      def normalize_hex_attribute(attribute)
        raw = read_attribute(attribute)
        write_attribute(attribute, nil) if raw.blank? || auto_cover_text?(raw)
        return if read_attribute(attribute).blank?

        normalized = RecordingStudioPresskits::Cover::Hex.normalize(read_attribute(attribute))
        write_attribute(attribute, normalized) if normalized
      end

      def auto_cover_text?(value)
        RecordingStudioPresskits::Cover::Palette.new(colors: []).auto?(value)
      end

      def cover_color_must_be_hex
        add_hex_error(:cover_color, cover_color)
      end

      def cover_text_color_must_be_hex
        add_hex_error(:cover_text_color, cover_text_color)
      end

      def add_hex_error(attribute, value)
        return if value.blank? || RecordingStudioPresskits::Cover::Hex.valid?(value)

        errors.add(attribute, "must be a hex colour")
      end

      def validate_cover_palette?
        @cover_color_assigned && cover_color.present? && !RecordingStudioPresskits.any_cover_color?
      end

      def validate_cover_text_palette?
        @cover_text_color_assigned && cover_text_color.present? && !RecordingStudioPresskits.any_cover_text_color?
      end

      def cover_color_must_be_allowed
        add_palette_error(:cover_color, cover_color, @stored_cover_color_before_assign,
                          RecordingStudioPresskits.cover_palette)
      end

      def cover_text_color_must_be_allowed
        add_palette_error(:cover_text_color, cover_text_color, @stored_cover_text_color_before_assign,
                          RecordingStudioPresskits.cover_text_palette)
      end

      def add_palette_error(attribute, value, previous, palette)
        hex = RecordingStudioPresskits::Cover::Hex.normalize(value)
        return if palette.include?(hex)
        return if RecordingStudioPresskits::Cover::Hex.normalize(previous) == hex

        errors.add(attribute, "must be one of the host colours")
      end
    end
  end
end
