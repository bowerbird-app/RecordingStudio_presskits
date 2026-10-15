# frozen_string_literal: true

module RecordingStudioPresskits
  class CoversController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
