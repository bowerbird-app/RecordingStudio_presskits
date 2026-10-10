import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ids"]

  connect() {
    this.picker()?.loadAttachments?.({ reset: true })
  }

  queue(event) {
    const id = event.detail?.attachment?.id
    if (!id || !this.hasIdsTarget) return
    if (this.idsTarget.querySelector(`input[value="${CSS.escape(String(id))}"]`)) return

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "attachment_recording_ids[]"
    input.value = id
    this.idsTarget.appendChild(input)
    window.clearTimeout(this.submitTimer)
    this.submitTimer = window.setTimeout(() => this.submit(), 0)
  }

  submit() {
    this.element.querySelector("form[data-library-picker-form]")?.requestSubmit()
  }

  picker() {
    return this.application.getControllerForElementAndIdentifier(
      this.element,
      "recording-studio-attachable--attachment-image-picker"
    )
  }
}
