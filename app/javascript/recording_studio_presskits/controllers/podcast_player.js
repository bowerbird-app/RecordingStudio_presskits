// The iframe is created when play opens the modal and removed when it closes,
// so a hidden dialog never loads or keeps playing audio.

export function mountPlayer(stage, { url, title }) {
  const frame = document.createElement("iframe")
  frame.src = url
  frame.title = title
  frame.className = "h-full w-full border-0"
  frame.setAttribute("allow", "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture")
  frame.setAttribute("data-podcast-embed", "true")
  stage.replaceChildren(frame)
  return frame
}

export function clearPlayer(stage) {
  stage.replaceChildren()
}

export function shouldClear(event, root) {
  if (event.type === "keydown" && event.key === "Escape") return true

  const target = event.target
  if (!target || typeof target.closest !== "function") return false

  const closer = target.closest(
    "[data-action*='flat-pack--modal#close'], [data-action*='flat-pack--modal#clickBackdrop']"
  )
  return Boolean(closer && root.contains(closer))
}
