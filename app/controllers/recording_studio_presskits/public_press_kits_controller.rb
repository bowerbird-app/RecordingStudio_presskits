# frozen_string_literal: true

module RecordingStudioPresskits
  class PublicPressKitsController < ActionController::Base
    include RecordingStudio::UsesDefaultLayout

    def show
      @press_kit_recording = @parent_recording
      @press_kit = @parent_recordable
      @section_recordings = KitQuery.live_children(@press_kit_recording)
    end
  end
end
