import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy(event) {
    event.preventDefault()
    const text = this.textValue
    if (!text) return

    this.writeText(text)
  }

  async writeText(text) {
    if (navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(text)
        return
      } catch {
      }
    }

    const input = document.createElement("textarea")
    input.value = text
    input.setAttribute("readonly", "readonly")
    input.style.position = "fixed"
    input.style.opacity = "0"
    document.body.appendChild(input)
    input.select()
    document.execCommand("copy")
    input.remove()
  }
}
