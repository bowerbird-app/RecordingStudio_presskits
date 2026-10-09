import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 8000 }
  }

  connect() {
    if (this.timeoutValue <= 0) return

    this.timer = window.setTimeout(() => this.element.remove(), this.timeoutValue)
  }

  disconnect() {
    if (this.timer) window.clearTimeout(this.timer)
  }
}
