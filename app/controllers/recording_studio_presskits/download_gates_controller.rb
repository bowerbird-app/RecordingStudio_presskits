# frozen_string_literal: true

module RecordingStudioPresskits
  # Public confirmation step. Anonymous visitors can reach it, so this stays
  # off the signed-in engine ApplicationController.
  class DownloadGatesController < ActionController::Base
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    helper ::RecordingStudioDownloadable::Engine.helpers if defined?(::RecordingStudioDownloadable::Engine)

    protect_from_forgery with: :exception
    layout "recording_studio_presskits/download_gate"

    before_action :set_gate_actor

    def show
      recording = gated_recording
      return if performed?

      @recording = recording
    end

    def update
      recording = gated_recording
      return if performed?

      remember_confirmation(recording)
      @recording = recording
      return render_step(recording) if turbo_frame_request?

      redirect_to KitDownloadGate.continuation_url(recording: recording, actor: gate_actor, request: request)
    end

    private

    def gated_recording
      recording = live_recording
      if recording.nil?
        head :not_found
        return
      end

      unless allowed?(recording)
        head :forbidden
        return
      end

      recording
    end

    def live_recording
      recording = RecordingStudio::Recording.find_by(id: params[:recording_id])
      return if recording.blank?
      return if recording.respond_to?(:trashed?) && recording.trashed?
      return unless KitDownloadGate.covers?(recording)

      recording
    end

    def allowed?(recording)
      return false unless defined?(RecordingStudioDownloadable::Authorization)

      RecordingStudioDownloadable::Authorization.allowed?(
        action: recording.downloadable_action,
        actor: gate_actor,
        recording: recording
      )
    rescue StandardError
      false
    end

    def remember_confirmation(recording)
      kit = KitDownloadGate.kit_for(recording)
      entries = KitDownloadGate.entries(session[KitDownloadGate::SESSION_KEY])
      entries[kit.id.to_s] = confirmation_entry(recording, entries[kit.id.to_s] || {})
      session[KitDownloadGate::SESSION_KEY] = entries
      assign_current_gate(entries)
    end

    def confirmation_entry(recording, entry)
      if params[:confirmed].to_s == "1"
        entry["confirmed"] = true
        session[:recording_studio_downloadable_autostart] = recording.id
      else
        entry["confirmed"] = false
        flash[:alert] = I18n.t("recording_studio_presskits.download_gate.unchecked")
      end
      entry
    end

    def assign_current_gate(entries)
      return unless defined?(Current) && Current.respond_to?(:download_gate=)

      Current.download_gate = entries
    end

    def render_step(recording)
      render partial: "recording_studio_presskits/download_gates/frame", locals: { recording: recording }
    end

    def set_gate_actor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = gate_actor
    end

    def gate_actor
      return current_user if respond_to?(:current_user, true)

      nil
    end
  end
end
