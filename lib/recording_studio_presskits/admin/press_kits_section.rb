# frozen_string_literal: true

module RecordingStudioPresskits
  module Admin
    class PressKitsSection < RecordingStudioAdmin::Section
      key "press_kits"
      icon :folder
      title "Press kits"
      subtitle "What's live, and what still needs a push"
      blast_radius :site

      widget "widgets.press_kits.published"
      widget "widgets.press_kits.unpublished"
    end
  end
end
