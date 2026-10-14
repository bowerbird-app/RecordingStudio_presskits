import { Controller } from "@hotwired/stimulus"
import { clearPlayer, mountPlayer, shouldClear } from "controllers/recording_studio_presskits/podcast_player"

// Flatpack Modal owns focus, Escape, and the backdrop. This only inserts the
// player while that dialog is open.
export default class extends Controller {
  static targets = ["stage"]
  static values = {
    embedUrl: String,
    title: String
  }

  mount() {
    if (!this.hasStageTarget || !this.embedUrlValue) return

    mountPlayer(this.stageTarget, { url: this.embedUrlValue, title: this.titleValue })
  }

  clear(event) {
    if (!this.hasStageTarget || !shouldClear(event, this.element)) return

    clearPlayer(this.stageTarget)
  }
}
