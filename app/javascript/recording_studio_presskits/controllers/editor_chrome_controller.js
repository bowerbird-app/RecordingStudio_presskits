import { Controller } from "@hotwired/stimulus"

// Flatpack FAB has no tap-to-activate or hover-only visibility API.
// Desktop uses CSS hover / focus-within. Touch (`hover: none`) uses this
// controller so tint and FAB appear only on the active region.
export default class extends Controller {
  onPointerDown(event) {
    if (!this.touch()) return

    const region = event.target.closest("[data-presskits-editor-region]")
    if (region && this.element.contains(region)) {
      this.activate(region)
      return
    }

    if (this.overlay(event.target)) return

    this.clear()
  }

  activate(region) {
    this.regions().forEach((el) => {
      if (el === region) {
        el.setAttribute("data-pk-edit-active", "")
      } else {
        el.removeAttribute("data-pk-edit-active")
      }
    })
  }

  clear() {
    this.regions().forEach((el) => {
      el.removeAttribute("data-pk-edit-active")
      if (el.contains(document.activeElement)) document.activeElement.blur()
    })
  }

  regions() {
    return this.element.querySelectorAll("[data-presskits-editor-region]")
  }

  touch() {
    return window.matchMedia("(hover: none)").matches
  }

  overlay(node) {
    return Boolean(node.closest("dialog, [role='dialog']"))
  }
}
