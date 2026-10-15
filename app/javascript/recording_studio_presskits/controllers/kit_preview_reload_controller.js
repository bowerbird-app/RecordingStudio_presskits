import { Controller } from "@hotwired/stimulus"

// Flatpack list-orderable saves over fetch. Refresh only the preview frame
// so the Reorder modal stays open. A full visit replays the pre-drag cache
// and tears the modal down mid-settle.
//
// Flatpack's modal enter animation sets dialog.style.scale. A scaled dialog
// is the containing block for the list's position:fixed drag row, so the row
// jumps. Scale is cleared once the modal is open, and again on pointerdown
// before the drag measures the row.
const SCALE_SETTLE_MS = 450

export default class extends Controller {
  connect() {
    this.modal = this.element.closest("#presskits-sections-modal")
    this.onPointerDown = () => this.clearScale()
    this.element.addEventListener("pointerdown", this.onPointerDown, true)

    if (!this.modal || typeof MutationObserver !== "function") return

    this.observer = new MutationObserver(() => this.releaseDragScale())
    this.observer.observe(this.modal, { attributes: true, attributeFilter: ["aria-hidden", "class"] })
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this.onPointerDown, true)
    this.observer?.disconnect()
    window.clearTimeout(this.scaleTimer)
  }

  reload() {
    const frame = document.getElementById("presskits-editor-sections")
    if (frame?.tagName === "TURBO-FRAME") {
      const url = new URL(window.location.href)
      url.searchParams.set("presskits_sections", Date.now().toString())
      frame.src = url.toString()
      return
    }

    const turbo = window.Turbo
    if (turbo?.visit) {
      turbo.visit(window.location.href, { action: "replace" })
      return
    }

    window.location.reload()
  }

  releaseDragScale() {
    const open = this.modal.getAttribute("aria-hidden") === "false"
    if (!open) {
      this.released = false
      return
    }
    if (this.released) return

    this.released = true
    window.clearTimeout(this.scaleTimer)
    this.scaleTimer = window.setTimeout(() => this.clearScale(), SCALE_SETTLE_MS)
  }

  clearScale() {
    const dialog = this.modal?.querySelector("[data-flat-pack--modal-target='dialog']")
    if (!dialog) return
    if (this.modal.getAttribute("aria-hidden") !== "false") return

    dialog.style.scale = "none"
  }
}
