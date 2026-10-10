# frozen_string_literal: true

module RecordingStudioPresskits
  class PublicPressKitsController < ActionController::Base
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)

    helper RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
    helper RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)

    before_action :set_public_actor

    def show
      # Publishable's RendersPublicPage instantiates this controller and calls
      # show without filters. Assign the request user here too, including nil.
      set_public_actor
      @press_kit_recording = @parent_recording
      @press_kit = @parent_recordable
      @presskits_presentation = Visibility.presentation_for(
        actor: public_actor,
        kit: @press_kit_recording,
        purpose: :public
      )
      @presskits_preview_reason = Visibility.preview_reason_for(@press_kit_recording)
      @section_recordings = sections_for_presentation
    end

    private

    def set_public_actor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = respond_to?(:current_user, true) ? current_user : nil
    end

    def public_actor
      return current_user if respond_to?(:current_user, true)

      return Current.actor if defined?(Current) && Current.respond_to?(:actor)

      return unless defined?(RecordingStudioPublishable)

      RecordingStudioPublishable.configuration.actor_for(controller: self)
    rescue StandardError
      nil
    end

    def sections_for_presentation
      return KitQuery.sections_for(@press_kit_recording) if @presskits_presentation == :full

      RecordingStudio::Recording.none
    end
  end
end
