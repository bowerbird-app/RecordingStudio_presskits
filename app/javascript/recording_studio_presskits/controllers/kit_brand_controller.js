import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  chooseSource(event) {
    const tab = event.target.closest("[role='tab']")
    if (!tab || !this.hasSourceTarget) return

    this.sourceTarget.value = tab.id.includes("custom") ? "custom" : "press_center"
  }
}
