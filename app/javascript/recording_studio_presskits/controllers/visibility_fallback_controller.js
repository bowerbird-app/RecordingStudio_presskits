import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fallback"]
  static values = { public: { type: String, default: "public" } }

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasFallbackTarget) return

    const hidden = this.selectedAudience() === this.publicValue
    this.fallbackTarget.hidden = hidden
  }

  selectedAudience() {
    const checked = this.element.querySelector("[name='visibility[audience]']:checked")
    return `${checked?.value || ""}`.trim()
  }
}
