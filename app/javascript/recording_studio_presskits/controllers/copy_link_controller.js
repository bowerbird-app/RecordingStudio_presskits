import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    copied: { type: String, default: "Link copied." },
    failed: { type: String, default: "Couldn't copy that link." }
  }

  copy(event) {
    event.preventDefault()
    const url = this.urlValue
    if (!url) {
      this.toast(this.failedValue, "danger")
      return
    }

    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(url).then(() => {
        this.toast(this.copiedValue, "success")
      }).catch(() => this.fallback(url))
      return
    }

    this.fallback(url)
  }

  fallback(url) {
    const input = document.createElement("textarea")
    input.value = url
    input.setAttribute("readonly", "")
    input.style.position = "fixed"
    input.style.top = "0"
    input.style.left = "-9999px"
    document.body.appendChild(input)
    input.select()

    let copied = false
    try {
      copied = document.execCommand("copy")
    } catch (_error) {
      copied = false
    }
    input.remove()
    this.toast(copied ? this.copiedValue : this.failedValue, copied ? "success" : "danger")
  }

  toast(text, style) {
    document.dispatchEvent(new CustomEvent("toast:add", { detail: { text, style } }))
  }
}
