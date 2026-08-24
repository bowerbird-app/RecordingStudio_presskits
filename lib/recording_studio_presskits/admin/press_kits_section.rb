# frozen_string_literal: true

module RecordingStudioPresskits
  module Admin
    class PressKitsSection < RecordingStudioAdmin::Section
      key "press_kits"
      icon :folder
      title "Press kits"
      subtitle "Kits people are filling right now"
      blast_radius :site

      widget "widgets.press_kits.list"
    end
  end
end
