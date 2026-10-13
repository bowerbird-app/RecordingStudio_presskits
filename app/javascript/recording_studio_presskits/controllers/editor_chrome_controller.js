import { Controller } from "@hotwired/stimulus"

// Flatpack FAB has no tap-to-activate or hover-only visibility API.
// Desktop uses CSS hover / focus-within. Touch (`hover: none`) uses this
// controller so tint and FAB appear only on the active region.
export default class extends Controller {
  connect() {
    this.releaseTrashFocusGuard = this.holdTrashArmFocus()
  }

  disconnect() {
    this.releaseTrashFocusGuard?.()
    this.releaseTrashFocusGuard = null
  }

  // TrashButton focuses its arm while its module connects, which can be
  // after this controller connects. That scrolls the editor to the last
  // section. Until the person acts, keep that focus from moving the page
  // and blur it so the action row stays hidden.
  holdTrashArmFocus() {
    if (window.__presskitsTrashArmFocusGuard) return () => {}
    window.__presskitsTrashArmFocusGuard = true

    const original = HTMLElement.prototype.focus
    let personActed = false
    const markActed = () => { personActed = true }
    window.addEventListener("pointerdown", markActed, { capture: true, once: true })
    window.addEventListener("keydown", markActed, { capture: true, once: true })
    window.addEventListener("wheel", markActed, { capture: true, once: true, passive: true })

    HTMLElement.prototype.focus = function (options) {
      if (!personActed && this.classList?.contains("fp-trash-button__arm")) {
        return original.call(this, { ...(options || {}), preventScroll: true })
      }
      return original.call(this, options)
    }

    const settle = () => {
      if (personActed) return
      const active = document.activeElement
      if (active?.classList?.contains("fp-trash-button__arm")) active.blur()
      if (window.scrollY !== 0 && !window.location.hash) window.scrollTo(0, 0)
    }
    const timers = [0, 250, 1000].map((delay) => window.setTimeout(settle, delay))

    return () => {
      timers.forEach((timer) => window.clearTimeout(timer))
      HTMLElement.prototype.focus = original
      window.__presskitsTrashArmFocusGuard = false
    }
  }

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
