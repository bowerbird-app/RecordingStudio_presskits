import { Controller } from "@hotwired/stimulus"

// Desktop uses CSS hover / focus-within for the header wash and section tint.
// Touch (`hover: none`) uses this controller so that tint follows the active region.
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

  // Flatpack navigable frames are loading="lazy" inside a hidden modal.
  // showLoading then sets visibility:hidden, so the frame never intersects
  // and the spinner stays. Eager plus an assigned src fetches before open.
  prepareEditorFrame(event) {
    if (event.type === "keydown" && event.key !== "Enter" && event.key !== " ") return

    const node = event.target instanceof Element ? event.target : event.target?.parentElement
    const trigger = node?.closest?.("[data-modal-id][data-turbo-frame]")
    if (!trigger) return

    const frame = document.getElementById(trigger.dataset.turboFrame)
    if (!frame || frame.tagName !== "TURBO-FRAME") return

    frame.loading = "eager"
    const href = trigger.getAttribute("href")
    if (!href || href.charAt(0) === "#") return
    if (frame.hasAttribute("complete") && frame.getAttribute("src") === href) return

    frame.src = href
  }

  onPointerDown(event) {
    this.prepareEditorFrame(event)
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
