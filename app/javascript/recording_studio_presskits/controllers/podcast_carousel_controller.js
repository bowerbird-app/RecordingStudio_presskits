import { Controller } from "@hotwired/stimulus"

// Flatpack has no scroller. Cards use CSS scroll-snap. This only shows the
// arrows when the row actually overflows, and steps one card at a time.
export default class extends Controller {
  static targets = ["scroller", "previous", "next"]

  connect() {
    this.onScroll = () => this.refresh()
    this.scrollerTarget.addEventListener("scroll", this.onScroll, { passive: true })
    if (typeof ResizeObserver !== "undefined") {
      this.observer = new ResizeObserver(() => this.refresh())
      this.observer.observe(this.scrollerTarget)
    }
    this.refresh()
  }

  disconnect() {
    this.scrollerTarget.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  previous() {
    this.step(-1)
  }

  next() {
    this.step(1)
  }

  step(direction) {
    const scroller = this.scrollerTarget
    const card = scroller.querySelector("[data-podcast-card]")
    const width = card ? card.getBoundingClientRect().width : scroller.clientWidth
    scroller.scrollBy({ left: direction * (width + 16), behavior: "smooth" })
  }

  refresh() {
    const scroller = this.scrollerTarget
    const max = scroller.scrollWidth - scroller.clientWidth
    const overflow = max > 1
    this.previousTarget.hidden = !(overflow && scroller.scrollLeft > 1)
    this.nextTarget.hidden = !(overflow && scroller.scrollLeft < max - 1)
  }
}
