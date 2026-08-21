# frozen_string_literal: true

require "recording_studio_presskits/admin/press_kits_published_widget"
require "recording_studio_presskits/admin/press_kits_unpublished_widget"
require "recording_studio_presskits/admin/press_kits_section"

module RecordingStudioPresskits
  module Admin
    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_widget(PressKitsPublishedWidget)
        RecordingStudioAdmin.register_widget(PressKitsUnpublishedWidget)
        RecordingStudioAdmin.register_section(PressKitsSection)
      end
    end
  end
end
