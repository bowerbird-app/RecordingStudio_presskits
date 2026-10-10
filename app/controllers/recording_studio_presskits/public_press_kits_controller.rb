# frozen_string_literal: true

module RecordingStudioPresskits
  class PublicPressKitsController < ActionController::Base
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    helper ApplicationHelper
    helper RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
    helper RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)
    helper ::RecordingStudioDownloadable::Engine.helpers if defined?(::RecordingStudioDownloadable::Engine)

    before_action :set_public_actor

    def show
      @press_kit_recording = @parent_recording
      @press_kit = @parent_recordable
      @section_recordings = KitQuery.sections_for(@press_kit_recording)
    end

    private

    def set_public_actor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = respond_to?(:current_user, true) ? current_user : nil
    end
  end
end
