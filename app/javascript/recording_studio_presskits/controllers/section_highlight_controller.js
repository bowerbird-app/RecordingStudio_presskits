import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    enabled: { type: Boolean, default: false },
    timeout: { type: Number, default: 2400 }
  }

  connect() {
    if (!this.enabledValue) return

    this.element.scrollIntoView({ behavior: "smooth", block: "center" })
    this.timer = window.setTimeout(() => this.clear(), this.timeoutValue)
  }

  disconnect() {
    if (this.timer) window.clearTimeout(this.timer)
  }

  clear() {
    this.element.classList.remove("ring-2", "ring-[var(--color-primary)]")
  }
}
