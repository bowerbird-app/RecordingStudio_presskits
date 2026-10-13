# frozen_string_literal: true

# Development stand-in for a press center brand. Press kits does not depend on
# that gem. This lets the dummy show a kit inheriting ACME desk (#0F766E, serif).
module RecordingStudioPressCenters
  class Branding < RecordingStudioPresskits::BrandStyle
  end

  class << self
    def branding_for(recording)
      return unless under_acme_desk?(recording)

      Branding.new(brand_color: "#0F766E", font_family: "serif")
    end

    private

    def under_acme_desk?(recording)
      current = recording
      seen = {}
      while current && seen[current.try(:id)].nil?
        seen[current.try(:id)] = true
        label = current.try(:recordable).try(:title).presence || current.try(:recordable).try(:name).to_s
        return true if label == "ACME desk"

        current = current.respond_to?(:parent_recording) ? current.parent_recording : nil
      end
      false
    end
  end
end
