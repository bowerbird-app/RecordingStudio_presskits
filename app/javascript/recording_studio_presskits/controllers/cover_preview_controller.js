import { Controller } from "@hotwired/stimulus"

const LIGHT = "#F8FAFC"
const DARK = "#111827"

export default class extends Controller {
  static targets = ["surface"]

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasSurfaceTarget) return

    const color = this.selectedColor()
    const textColor = this.contrastText(color)
    const title = this.titleValue()
    const description = this.descriptionValue()

    this.surfaceTarget.style.backgroundColor = color
    this.surfaceTarget.style.color = textColor

    const heading = this.surfaceTarget.querySelector("h1, h2, h3, p")
    if (heading) {
      heading.textContent = title
      heading.style.color = textColor
    }

    const subtitle = this.subtitleElement(heading)
    if (description) {
      if (subtitle) {
        subtitle.textContent = description
        subtitle.hidden = false
        subtitle.style.color = textColor
      }
    } else if (subtitle) {
      subtitle.textContent = ""
      subtitle.hidden = true
    }
  }

  selectedColor() {
    const named = this.element.querySelector("[name='press_kit[cover_color]']:checked")
    if (named?.value) return this.normalizeHex(named.value)

    const colorInput = this.element.querySelector("[name='press_kit[cover_color]']")
    return this.normalizeHex(colorInput?.value) || "#1F2937"
  }

  titleValue() {
    return this.element.querySelector("[name='press_kit[title]']")?.value?.trim() || "Press kit"
  }

  descriptionValue() {
    return this.element.querySelector("[name='press_kit[description]']")?.value?.trim() || ""
  }

  subtitleElement(heading) {
    if (!heading) return null

    return heading.nextElementSibling
  }

  normalizeHex(value) {
    const raw = `${value || ""}`.trim()
    if (!raw) return null

    const digits = raw.replace(/^#/, "")
    if (!/^[0-9A-Fa-f]{3}$|^[0-9A-Fa-f]{6}$/.test(digits)) return null

    const expanded = digits.length === 3 ? digits.split("").map((digit) => digit + digit).join("") : digits
    return `#${expanded.toUpperCase()}`
  }

  contrastText(background) {
    const hex = this.normalizeHex(background)
    if (!hex) return DARK

    return this.contrast(hex, LIGHT) >= this.contrast(hex, DARK) ? LIGHT : DARK
  }

  contrast(one, two) {
    const first = this.luminance(one)
    const second = this.luminance(two)
    const lighter = Math.max(first, second)
    const darker = Math.min(first, second)
    return (lighter + 0.05) / (darker + 0.05)
  }

  luminance(hex) {
    const [red, green, blue] = this.rgb(hex).map((channel) => this.linearize(channel / 255))
    return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  }

  rgb(hex) {
    return [
      parseInt(hex.slice(1, 3), 16),
      parseInt(hex.slice(3, 5), 16),
      parseInt(hex.slice(5, 7), 16)
    ]
  }

  linearize(channel) {
    return channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
  }
}
