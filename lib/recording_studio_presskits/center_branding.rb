# frozen_string_literal: true

module RecordingStudioPresskits
  # Optional look-up for a parent press center's brand. Press kits does not
  # depend on that gem. A missing constant, or nil branding, leaves the
  # Flatpack theme alone.
  module CenterBranding
    def branding_style_for(kit_recording)
      return unless defined?(RecordingStudioPressCenters)

      RecordingStudioPressCenters.branding_for(kit_recording)&.style_attribute.presence
    end
  end
end
