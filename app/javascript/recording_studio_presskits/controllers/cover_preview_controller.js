import { Controller } from "@hotwired/stimulus"

const LIGHT = "#F8FAFC"
const DARK = "#111827"
const AUTO = "auto"
const AA_RATIO = 4.5

export default class extends Controller {
  static targets = ["surface", "contrastHint"]

  connect() {
    this.sync()
  }

  sync(event) {
    if (!this.hasSurfaceTarget) return

    this.captureCustomText(event)

    const color = this.selectedColor()
    const textColor = this.selectedTextColor(color)
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

    this.toggleContrastHint(color, textColor)
  }

  captureCustomText(event) {
    const input = event?.target
    if (input?.name !== "press_kit[cover_text_swatch]") return

    const hex = this.normalizeHex(input.value)
    if (!hex) return

    const custom = this.customTextRadio()
    if (!custom) return

    custom.value = hex
    custom.checked = true
  }

  selectedColor() {
    const named = this.element.querySelector("[name='press_kit[cover_color]']:checked")
    if (named?.value) return this.normalizeHex(named.value)

    const colorInput = this.element.querySelector("[name='press_kit[cover_color]']")
    return this.normalizeHex(colorInput?.value) || "#1F2937"
  }

  selectedTextColor(background) {
    const named = this.element.querySelector("[name='press_kit[cover_text_color]']:checked")
    if (!named || this.isAuto(named.value)) return this.contrastText(background)

    return this.normalizeHex(named.value) || this.contrastText(background)
  }

  customTextRadio() {
    return [...this.element.querySelectorAll("[name='press_kit[cover_text_color]']")]
      .find((radio) => !this.isAuto(radio.value))
  }

  isAuto(value) {
    return `${value || ""}`.trim().toLowerCase() === AUTO
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

  toggleContrastHint(background, foreground) {
    if (!this.hasContrastHintTarget) return

    this.contrastHintTarget.hidden = !this.lowContrast(background, foreground)
  }

  lowContrast(background, foreground) {
    const bg = this.normalizeHex(background)
    const fg = this.normalizeHex(foreground)
    if (!bg || !fg) return false

    return this.contrast(bg, fg) < AA_RATIO
  }

  normalizeHex(value) {
    const raw = `${value || ""}`.trim()
    if (!raw || this.isAuto(raw)) return null

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
