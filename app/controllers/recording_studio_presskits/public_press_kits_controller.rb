# frozen_string_literal: true

module RecordingStudioPresskits
  class PublicPressKitsController < ActionController::Base
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)

    helper RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
    helper RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)

    def show
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

    def public_actor
      return Current.actor if current_actor_present?
      return current_user if respond_to?(:current_user, true) && current_user
      return unless defined?(RecordingStudioPublishable)

      RecordingStudioPublishable.configuration.actor_for(controller: self)
    rescue StandardError
      nil
    end

    def current_actor_present?
      defined?(Current) && Current.respond_to?(:actor) && Current.actor.present?
    end

    def sections_for_presentation
      return KitQuery.sections_for(@press_kit_recording) if @presskits_presentation == :full

      RecordingStudio::Recording.none
    end
  end
end
