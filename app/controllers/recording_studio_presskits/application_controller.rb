# frozen_string_literal: true

module RecordingStudioPresskits
  class ApplicationController < ActionController::Base
    include RecordingStudio::UsesDefaultLayout
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    if defined?(RecordingStudio::RootSwitchable::ControllerSupport)
      include RecordingStudio::RootSwitchable::ControllerSupport
    end

    protect_from_forgery with: :exception
    layout "recording_studio/default_layout"

    helper ::RecordingStudio::LayoutHelper if defined?(::RecordingStudio::LayoutHelper)
    helper ::RecordingStudioAccessible::AvatarsHelper if defined?(::RecordingStudioAccessible::AvatarsHelper)

    before_action :authenticate_presskits_actor!
    before_action :set_presskits_current_actor

    helper_method :current_presskits_root

    private

    def authenticate_presskits_actor!
      method_name = RecordingStudioPresskits.configuration.authentication_method
      return send(method_name) if method_name && respond_to?(method_name, true)

      head :unauthorized
    end

    def set_presskits_current_actor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = presskits_actor
    end

    def presskits_actor
      return Current.actor if defined?(Current) && Current.respond_to?(:actor) && Current.actor.present?

      method_name = RecordingStudioPresskits.configuration.current_actor_method
      send(method_name) if method_name && respond_to?(method_name, true)
    end

    def authorize_recording!(recording, role:)
      unless presskits_actor
        head :unauthorized
        return
      end

      return if recording &&
                RecordingStudioAccessible.authorized?(actor: presskits_actor, recording: recording, role: role)

      head :forbidden
    end

    def current_presskits_root
      return current_root_recording if respond_to?(:current_root_recording)

      nil
    end

    def require_root!
      return if current_presskits_root.present?

      head :forbidden
    end

    def load_press_kit(id)
      KitQuery.for_root(current_presskits_root).find_by(id: id)
    end
  end
end
