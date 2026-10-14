import assert from "node:assert/strict"
import test from "node:test"

class Element {
  constructor() {
    this.attrs = {}
    this.children = []
    this.parent = null
    this.className = ""
  }

  setAttribute(name, value) {
    this.attrs[name] = String(value)
  }

  getAttribute(name) {
    return this.attrs[name]
  }

  set src(value) {
    this.setAttribute("src", value)
  }

  get src() {
    return this.getAttribute("src")
  }

  set title(value) {
    this.setAttribute("title", value)
  }

  get title() {
    return this.getAttribute("title")
  }

  append(...nodes) {
    nodes.forEach((node) => {
      node.parent = this
      this.children.push(node)
    })
  }

  replaceChildren(...nodes) {
    this.children = []
    this.append(...nodes)
  }

  contains(node) {
    let current = node
    while (current) {
      if (current === this) return true
      current = current.parent
    }
    return false
  }

  closest(selector) {
    let current = this
    while (current) {
      if (matches(current, selector)) return current
      current = current.parent
    }
    return null
  }
}

function matches(node, selector) {
  const action = node.attrs["data-action"] || ""
  return selector.split(",").some((part) => {
    const wanted = part.match(/data-action\*='([^']+)'/)
    return wanted ? action.includes(wanted[1]) : false
  })
}

globalThis.document = {
  createElement() {
    return new Element()
  }
}

const { clearPlayer, mountPlayer, shouldClear } = await import(
  "../app/javascript/recording_studio_presskits/controllers/podcast_player.js"
)

test("mount creates one iframe and clear removes it", () => {
  const stage = new Element()
  const frame = mountPlayer(stage, {
    url: "https://open.spotify.com/embed/episode/abc",
    title: "Play: Pilot"
  })

  assert.equal(stage.children.length, 1)
  assert.equal(frame.getAttribute("src"), "https://open.spotify.com/embed/episode/abc")
  assert.equal(frame.title, "Play: Pilot")
  assert.equal(frame.getAttribute("data-podcast-embed"), "true")
  assert.match(frame.getAttribute("allow"), /autoplay/)

  clearPlayer(stage)
  assert.equal(stage.children.length, 0)
})

test("close, escape, and the backdrop clear the player", () => {
  const root = new Element()
  const close = new Element()
  close.setAttribute("data-action", "flat-pack--modal#close")
  const backdrop = new Element()
  backdrop.setAttribute("data-action", "click->flat-pack--modal#clickBackdrop")
  const play = new Element()
  play.setAttribute("data-action", "recording-studio-presskits--podcast-player#mount")
  root.append(close, backdrop, play)

  assert.equal(shouldClear({ type: "keydown", key: "Escape", target: play }, root), true)
  assert.equal(shouldClear({ type: "click", target: close }, root), true)
  assert.equal(shouldClear({ type: "click", target: backdrop }, root), true)
  assert.equal(shouldClear({ type: "click", target: play }, root), false)
  assert.equal(shouldClear({ type: "keydown", key: "Enter", target: play }, root), false)
})
