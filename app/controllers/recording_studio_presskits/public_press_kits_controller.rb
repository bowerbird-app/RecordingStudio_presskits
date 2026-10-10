# frozen_string_literal: true

module RecordingStudioPresskits
  class PublicPressKitsController < ActionController::Base
    helper RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
    helper RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)

    def show
      @press_kit_recording = @parent_recording
      @press_kit = @parent_recordable
      @section_recordings = KitQuery.sections_for(@press_kit_recording)
    end
  end
end
