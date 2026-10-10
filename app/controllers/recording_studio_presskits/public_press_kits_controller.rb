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
      return if Current.respond_to?(:actor) && Current.actor.present?
      return unless respond_to?(:current_user, true)

      Current.actor = current_user
    end
  end
end
