import { Controller } from "@hotwired/stimulus"

// Public text only. Eight lines stay visible until Show more.
// The editor does not mount this controller.
export default class extends Controller {
  static targets = ["body", "fade", "toggle"]
  static values = {
    moreLabel: String,
    lessLabel: String
  }

  toggle(event) {
    event.preventDefault()
    this.expanded = !this.expanded
  }

  get expanded() {
    return this.hasToggleTarget && this.toggleTarget.getAttribute("aria-expanded") === "true"
  }

  set expanded(value) {
    if (!this.hasToggleTarget || !this.hasBodyTarget) return

    this.toggleTarget.setAttribute("aria-expanded", value ? "true" : "false")
    this.bodyTarget.classList.toggle("max-h-[14rem]", !value)
    this.bodyTarget.classList.toggle("overflow-hidden", !value)
    if (this.hasFadeTarget) this.fadeTarget.hidden = value

    const label = this.toggleTarget.querySelector("span")
    if (label) label.textContent = value ? this.lessLabelValue : this.moreLabelValue
  }
}
