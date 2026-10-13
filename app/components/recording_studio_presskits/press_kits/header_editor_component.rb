# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, title:, description:, subtitle: nil, brand_color: nil, # rubocop:disable Metrics/ParameterLists
                     font_family: nil, brand_source: nil, location: nil)
        super()
        @press_kit_recording = press_kit_recording
        @title = title
        @description = description
        @subtitle = subtitle
        @brand_color = brand_color
        @font_family = font_family
        @brand_source = brand_source
        @location = location
      end

      def header_location
        @location || RecordingStudio::Location::Location.new
      end

      def header_title
        @title.to_s
      end

      def header_description
        @description.to_s
      end

      def header_subtitle
        @subtitle.to_s
      end

      def inherit_available?
        kit_branding.inherit_available?
      end

      def press_center_tab?
        return false unless inherit_available?

        source = @brand_source.to_s
        return source == "press_center" if source.present?

        explicit_color.blank? && explicit_font_key.blank?
      end

      def default_tab
        press_center_tab? ? 0 : 1
      end

      def brand_source_value
        press_center_tab? ? "press_center" : "custom"
      end

      def font_options
        if defined?(RecordingStudioPressCenters::Branding) &&
           RecordingStudioPressCenters::Branding.respond_to?(:swatch_options)
          return RecordingStudioPressCenters::Branding.swatch_options
        end

        BrandStyle.swatch_options
      end

      def custom_font_swatch
        BrandStyle.swatch_css_for(explicit_font_key || inherited_font_family)
      end

      def custom_color
        explicit_color || inherited_brand_color
      end

      def press_center_summary
        "#{inherited_font_family.capitalize} · #{inherited_brand_color}"
      end

      def cancel_path
        helpers.edit_press_kit_path(@press_kit_recording)
      end

      def cover_controls
        @cover_controls ||= HeaderCoverControls.new(helpers, @press_kit_recording)
      end

      private

      def kit_branding
        @kit_branding ||= KitBranding.for(@press_kit_recording)
      end

      def inherited_font_family
        kit_branding.inherited_font_family
      end

      def inherited_brand_color
        kit_branding.inherited_brand_color
      end

      def explicit_font_key
        key = BrandStyle.normalize_font(@font_family)
        key.is_a?(String) ? key : nil
      end

      def explicit_color
        color = BrandStyle.normalize_color(@brand_color)
        color.is_a?(String) ? color : nil
      end
    end
  end
end
