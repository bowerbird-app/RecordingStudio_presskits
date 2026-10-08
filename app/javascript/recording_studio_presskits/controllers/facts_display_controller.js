import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["columns"]
  static values = { cards: { type: String, default: "cards" } }

  connect() {
    this.toggle()
  }

  toggle() {
    const show = this.selectedStyle() === this.cardsValue
    if (!this.hasColumnsTarget) return

    this.columnsTarget.hidden = !show
    this.columnsTarget.querySelectorAll("select, input, button").forEach((element) => {
      element.disabled = !show
    })
  }

  selectedStyle() {
    const named = this.element.querySelector("[name='facts_section[display_style]']")
    return named?.value || this.element.querySelector("select")?.value
  }
}
