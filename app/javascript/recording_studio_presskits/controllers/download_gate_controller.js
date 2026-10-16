import { Controller } from "@hotwired/stimulus"

// Keeps a gated download on this page. The button opens the Flatpack modal.
// A 409 from the package iframe asks this controller to stay instead of
// sending the window to continuation_url. Each button listens for its own
// recording, so a kit zip and a section zip on the same page do not open
// each other's modal.
export default class extends Controller {
  static values = {
    modalId: String,
    recordingId: String
  }

  hold(event) {
    const url = event.detail?.continuationUrl || ""
    if (this.hasRecordingIdValue && !url.includes(this.recordingIdValue)) return

    event.preventDefault()
    const modal = document.getElementById(this.modalIdValue)
    if (!modal) return

    this.application.getControllerForElementAndIdentifier(modal, "flat-pack--modal")?.open()
  }
}
