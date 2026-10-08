# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsController < ApplicationController
    before_action :require_root!
    before_action :set_credit, only: %i[edit update destroy]

    def index
      authorize_recording!(current_presskits_root, role: :view)
      return if performed?

      @credit_recordings = Credits.active_for_root(current_presskits_root)
    end

    def search
      authorize_recording!(current_presskits_root, role: :view)
      return if performed?

      render json: Credits::Picker.search(current_presskits_root, params[:q])
    end

    def new
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      @credit = Credit.new
    end

    def create
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      recording = create_credit
      return render json: Credits::Picker.created(recording) if request.format.json?

      redirect_to edit_credit_path(recording), notice: "Credit is ready."
    rescue ActiveRecord::RecordInvalid
      render_invalid_credit
    end

    def edit
      authorize_recording!(current_presskits_root, role: :edit)
    end

    def update
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      revise_credit
      redirect_to edit_credit_path(@credit_recording), notice: "Saved."
    rescue ActiveRecord::RecordInvalid
      @credit = @credit_recording.recordable
      flash.now[:alert] = "Give them a name."
      render :edit, status: :unprocessable_entity
    end

    def destroy
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      Credits.trash!(@credit_recording, actor: presskits_actor)
      redirect_to credits_path, notice: "Moved to trash."
    end

    private

    def set_credit
      @credit_recording = Credits.find_for_root(current_presskits_root, params[:id])
      return head :not_found if @credit_recording.blank?

      @credit = @credit_recording.recordable
    end

    def create_credit
      Credits.create!(root_recording: current_presskits_root, actor: presskits_actor, **credit_fields)
    end

    def revise_credit
      Credits.revise!(credit_recording: @credit_recording, root_recording: current_presskits_root, **credit_fields)
    end

    def credit_fields
      values = request.format.json? ? params.permit(:name, :url, :usual_role) : credit_params
      { name: values[:name], url: values[:url], usual_role: values[:usual_role] }
    end

    def credit_params
      params.require(:credit).permit(:name, :url, :usual_role)
    end

    def render_invalid_credit
      return render json: Credits::Picker.rejected, status: :unprocessable_entity if request.format.json?

      @credit = Credit.new(credit_params)
      flash.now[:alert] = "Give them a name."
      render :new, status: :unprocessable_entity
    end
  end
end
