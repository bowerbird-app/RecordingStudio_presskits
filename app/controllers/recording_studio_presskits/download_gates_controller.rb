# frozen_string_literal: true

module RecordingStudioPresskits
  # Public purpose step. Anonymous visitors can reach it, so this stays
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
      @page_title = page_title_for(recording)
    end

    def update
      recording = gated_recording
      return if performed?

      remember_purpose(recording)
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

    def remember_purpose(recording)
      kit = KitDownloadGate.kit_for(recording)
      entries = KitDownloadGate.entries(session[KitDownloadGate::SESSION_KEY])
      entries[kit.id.to_s] = purpose_entry(recording, entries[kit.id.to_s] || {})
      session[KitDownloadGate::SESSION_KEY] = entries
      assign_current_gate(entries)
    end

    def purpose_entry(recording, entry)
      purpose = KitDownloadGate.purpose_for({ "purpose" => params[:purpose] })
      if purpose
        entry["purpose"] = purpose
        session[:recording_studio_downloadable_autostart] = recording.id
      else
        entry.delete("purpose")
        flash[:alert] = I18n.t("recording_studio_presskits.download_gate.missing")
      end
      entry
    end

    def assign_current_gate(entries)
      return unless defined?(Current) && Current.respond_to?(:download_gate=)

      Current.download_gate = entries
    end

    def page_title_for(recording)
      kit = KitDownloadGate.kit_for(recording)
      entry = KitDownloadGate.entry_for(kit, session[KitDownloadGate::SESSION_KEY])
      key = KitDownloadGate.purpose_for(entry) ? "fetching" : "title"
      I18n.t("recording_studio_presskits.download_gate.#{key}")
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
