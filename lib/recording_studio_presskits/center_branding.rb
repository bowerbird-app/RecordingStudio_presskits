# frozen_string_literal: true

module RecordingStudioPresskits
  # Press kits does not depend on press centers. When that gem is loaded,
  # each field resolves as kit, then center, then the default. Otherwise
  # BrandStyle paints the same tokens from the kit and the defaults.
  module CenterBranding
    def branding_style_for(kit_recording)
      KitBranding.style_for(kit_recording).presence
    end
  end
end
