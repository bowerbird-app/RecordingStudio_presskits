# frozen_string_literal: true

# Host page that drops a kit onto its own screen. This is the kit embed.
# The published page is a different document and uses its own wrapper.
class KitEmbedsController < RecordingStudioPresskits::PublicPressKitsController
  # Host screen. The published kit uses the blank public document, so this
  # page is the embed sitting in the dummy app.
  layout "recording_studio/default_layout"

  def show
    set_public_actor
    @press_kit_recording = RecordingStudio::Recording.find(params[:id])
    @press_kit = @press_kit_recording.recordable
    @presskits_presentation = :full
    @section_recordings = RecordingStudioPresskits::KitQuery.sections_for(@press_kit_recording)
  end
end
