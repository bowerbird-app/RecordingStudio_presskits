# frozen_string_literal: true

module RecordingStudioPresskits
  # Kit value wins, then the parent press center, then the Flatpack default.
  # Nil on the kit means inherit. An explicit sans or #333333 is kept, so a
  # kit can force the default over a branded center.
  class KitBranding
    def self.for(kit_recording)
      new(kit_recording)
    end

    def self.style_for(kit_recording)
      self.for(kit_recording).style_attribute
    end

    def initialize(kit_recording)
      @kit_recording = kit_recording
    end

    def brand_color
      own(:brand_color) || from_center(:brand_color) || BrandStyle::DEFAULT_COLOR
    end

    def font_family
      own(:font_family) || from_center(:font_family) || BrandStyle::DEFAULT_FONT
    end

    def inherited_brand_color
      from_center(:brand_color) || BrandStyle::DEFAULT_COLOR
    end

    def inherited_font_family
      from_center(:font_family) || BrandStyle::DEFAULT_FONT
    end

    def inherit_available?
      defined?(RecordingStudioPressCenters) && RecordingStudioPressCenters.respond_to?(:branding_for)
    end

    def style_attribute
      painter.new(brand_color: brand_color, font_family: font_family).style_attribute
    end

    private

    def painter
      if defined?(RecordingStudioPressCenters::Branding)
        RecordingStudioPressCenters::Branding
      else
        BrandStyle
      end
    end

    def own(name)
      recordable.try(name).presence
    end

    def from_center(name)
      return unless inherit_available?

      branding = RecordingStudioPressCenters.branding_for(@kit_recording)
      return unless branding.respond_to?(name)

      branding.public_send(name).presence
    end

    def recordable
      return unless @kit_recording.respond_to?(:recordable)

      @kit_recording.recordable
    end
  end
end
