# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKitsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit, only: %i[show preview]

    def index
      authorize_recording!(current_presskits_root, role: :view)
      return if performed?

      @press_kit_recordings = KitQuery.for_root(current_presskits_root)
      @view = table_view? ? "table" : "cards"
    end

    def show
      authorize_recording!(@press_kit_recording, role: :view)
      return if performed?

      @section_recordings = KitQuery.live_children(@press_kit_recording)
      @picker_types = RecordingStudioPresskits.picker_types
    end

    def preview
      authorize_recording!(@press_kit_recording, role: :view)
      return if performed?

      @section_recordings = KitQuery.live_children(@press_kit_recording)
    end

    def new
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      @press_kit = PressKit.new
    end

    def create
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      title = press_kit_params[:title].to_s.strip
      return render_missing_title if title.blank?

      recording = current_presskits_root.record(PressKit) { |press_kit| press_kit.title = title }
      redirect_to press_kit_path(recording), notice: "Press kit is ready. Add a section when you are."
    rescue ActiveRecord::RecordInvalid
      render_missing_title(title)
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def table_view?
      params[:view].to_s == "table"
    end

    def press_kit_params
      params.fetch(:press_kit, {}).permit(:title)
    end

    def render_missing_title(title = nil)
      @press_kit = PressKit.new(title: title)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :new, status: :unprocessable_entity
    end
  end
end
